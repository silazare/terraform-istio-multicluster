# Istio Multi-Cluster Setup

# Generate CA certificates for secure multi-cluster communication
module "istio_cacerts" {
  source   = "./modules/cacerts"
  clusters = ["west", "asia"]
}

# Deploy Istio on West cluster
module "istio_west" {
  providers = {
    kubernetes = kubernetes.west
    helm       = helm.west
    kubectl    = kubectl.west
  }

  source        = "./modules/istio"
  network       = "west-network"
  mesh_id       = "production-mesh"
  cluster_name  = "west-cluster"
  istio_version = "1.27.0"
  ca_root       = module.istio_cacerts.root_cert
  cert          = module.istio_cacerts.certs["west"]
  key           = module.istio_cacerts.keys["west"]

  # Configure strict mTLS for specific namespaces
  mtls_namespaces = {
    "secure" = {
      peer_auth_name = "secure-mtls"
    }
  }

  depends_on = [
    module.eks_west,
    module.istio_cacerts
  ]
}

# Deploy Istio on Asia cluster  
module "istio_asia" {
  providers = {
    kubernetes = kubernetes.asia
    helm       = helm.asia
    kubectl    = kubectl.asia
  }

  source        = "./modules/istio"
  network       = "asia-network"
  mesh_id       = "production-mesh"
  cluster_name  = "asia-cluster"
  istio_version = "1.27.0"
  ca_root       = module.istio_cacerts.root_cert
  cert          = module.istio_cacerts.certs["asia"]
  key           = module.istio_cacerts.keys["asia"]

  # Configure strict mTLS for specific namespaces
  mtls_namespaces = {
    "secure" = {
      peer_auth_name = "secure-mtls"
    }
  }

  depends_on = [
    module.eks_asia,
    module.istio_cacerts
  ]
}

# Cross-cluster service discovery - West to Asia
module "remote_secret_west_to_asia" {
  providers = {
    kubernetes.local  = kubernetes.west
    kubernetes.remote = kubernetes.asia
  }

  source = "./modules/remote_secret"

  cluster_name = "west-cluster"
  ca_data      = module.eks_west.cluster_certificate_authority_data
  server       = module.eks_west.cluster_endpoint

  depends_on = [
    module.istio_west,
    module.istio_asia
  ]
}

# Cross-cluster service discovery - Asia to West  
module "remote_secret_asia_to_west" {
  providers = {
    kubernetes.local  = kubernetes.asia
    kubernetes.remote = kubernetes.west
  }

  source = "./modules/remote_secret"

  cluster_name = "asia-cluster"
  ca_data      = module.eks_asia.cluster_certificate_authority_data
  server       = module.eks_asia.cluster_endpoint

  depends_on = [
    module.istio_west,
    module.istio_asia
  ]
}
