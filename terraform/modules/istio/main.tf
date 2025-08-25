# Istio Multi-Cluster Deployment Module
# Deploys namespaces, secrets, helm releases, and east-west gateway

# Create istio-system namespace with network topology labels
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"

    labels = {
      "topology.istio.io/network" = var.network
      # Note: No istio-injection label - allows webhook to work for image replacement
      # Gateway pods will have sidecar.istio.io/inject=false to prevent sidecar injection
    }
  }
}

# Create cacerts secret for cross-cluster mTLS
resource "kubernetes_secret" "cacerts" {
  metadata {
    name      = "cacerts"
    namespace = kubernetes_namespace.istio_system.metadata[0].name
  }

  data = {
    "ca-cert.pem"    = var.cert
    "ca-key.pem"     = var.key
    "root-cert.pem"  = var.ca_root
    "cert-chain.pem" = "${var.cert}${var.ca_root}"
  }

  depends_on = [kubernetes_namespace.istio_system]
}

# Deploy Istio base components
resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = kubernetes_namespace.istio_system.metadata[0].name
  create_namespace = false
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.istio_version
  timeout          = 300
  cleanup_on_fail  = true

  depends_on = [kubernetes_secret.cacerts]
}

# Deploy Istio control plane (istiod)
resource "helm_release" "istiod" {
  name             = "istiod"
  namespace        = kubernetes_namespace.istio_system.metadata[0].name
  create_namespace = false
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = var.istio_version
  timeout          = 900
  cleanup_on_fail  = true
  wait             = true

  # Multi-cluster configuration using values
  values = [
    yamlencode({
      global = {
        meshID = var.mesh_id
        multiCluster = {
          clusterName = var.cluster_name
        }
        network = var.network
      }
      meshConfig = {
        defaultConfig = {
          proxyMetadata = {
            ISTIO_META_DNS_CAPTURE = "true"
          }
        }
      }
      pilot = {
        env = {
          EXTERNAL_ISTIOD = "true"
        }
      }
    })
  ]

  depends_on = [helm_release.istio_base]
}

# Deploy East-West Gateway for cross-cluster communication
resource "helm_release" "eastwest_gateway" {
  name             = "istio-eastwestgateway"
  namespace        = kubernetes_namespace.istio_system.metadata[0].name
  create_namespace = false
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = var.istio_version
  timeout          = 600
  cleanup_on_fail  = true

  # Configuration with NLB for proper TLS passthrough
  values = [
    yamlencode({
      name           = "istio-eastwestgateway"
      networkGateway = var.network
      service = {
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
        }
        type = "LoadBalancer"
      }
    })
  ]

  depends_on = [
    helm_release.istiod,
  ]
}

# Gateway resource for cross-network traffic
resource "kubectl_manifest" "cross_network_gateway" {
  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "cross-network-gateway"
      namespace = kubernetes_namespace.istio_system.metadata[0].name
    }
    spec = {
      selector = {
        istio = "eastwestgateway"
      }
      servers = [
        {
          port = {
            number   = 15443
            name     = "tls"
            protocol = "TLS"
          }
          tls = {
            mode = "AUTO_PASSTHROUGH"
          }
          hosts = ["*.local"]
        }
      ]
    }
  })

  depends_on = [helm_release.eastwest_gateway]
}

# Expose the control plane
resource "kubectl_manifest" "expose_istiod" {
  yaml_body = yamlencode({
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "istiod-gateway"
      namespace = kubernetes_namespace.istio_system.metadata[0].name
    }
    spec = {
      selector = {
        istio = "eastwestgateway"
      }
      servers = [
        {
          port = {
            number   = 15012
            name     = "tls-istiod"
            protocol = "TLS"
          }
          tls = {
            mode = "PASSTHROUGH"
          }
          hosts = ["*"]
        }
      ]
    }
  })

  depends_on = [helm_release.eastwest_gateway]
}

# Create namespaces for Istio labeling and strict mTLS enforcement
resource "kubernetes_namespace" "mtls_namespaces" {
  for_each = var.mtls_namespaces

  metadata {
    name = each.key
    labels = {
      "istio-injection" = "enabled"
      "security"        = "strict-mtls"
    }
  }

  depends_on = [helm_release.istiod]
}

# Strict mTLS PeerAuthentication policies
resource "kubectl_manifest" "peer_authentication_strict" {
  for_each = var.mtls_namespaces

  yaml_body = yamlencode({
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = each.value.peer_auth_name
      namespace = each.key
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  })

  depends_on = [kubernetes_namespace.mtls_namespaces]
}
