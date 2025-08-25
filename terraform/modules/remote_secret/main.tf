# Remote Secret Module for Cross-Cluster Service Discovery
# Creates service account and secret for remote cluster access

# Create service account for cross-cluster access in the local cluster
resource "kubernetes_service_account" "istio_reader" {
  provider = kubernetes.local

  metadata {
    name      = "istio-reader-service-account"
    namespace = "istio-system"
  }
}

# Create cluster role for service discovery
resource "kubernetes_cluster_role" "istio_reader" {
  provider = kubernetes.local

  metadata {
    name = "istio-reader-service-account-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "pods", "services", "endpoints"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["*"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["security.istio.io"]
    resources  = ["*"]
    verbs      = ["get", "watch", "list"]
  }
}

# Bind cluster role to service account
resource "kubernetes_cluster_role_binding" "istio_reader" {
  provider = kubernetes.local

  metadata {
    name = "istio-reader-service-account-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.istio_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.istio_reader.metadata[0].name
    namespace = kubernetes_service_account.istio_reader.metadata[0].namespace
  }
}

# Create token secret for the service account
resource "kubernetes_secret" "istio_reader_token" {
  provider = kubernetes.local

  metadata {
    name      = "istio-reader-service-account-token"
    namespace = "istio-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.istio_reader.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account.istio_reader]
}

# Get the token from the secret
data "kubernetes_secret" "istio_reader_token" {
  provider = kubernetes.local

  metadata {
    name      = kubernetes_secret.istio_reader_token.metadata[0].name
    namespace = "istio-system"
  }

  depends_on = [kubernetes_secret.istio_reader_token]
}

# Create remote secret in the remote cluster
resource "kubernetes_secret" "remote_secret" {
  provider = kubernetes.remote

  metadata {
    name      = "istio-remote-secret-${var.cluster_name}"
    namespace = "istio-system"
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = var.cluster_name
    }
  }

  data = {
    "${var.cluster_name}" = yamlencode({
      apiVersion = "v1"
      kind       = "Config"
      clusters = [
        {
          cluster = {
            certificate-authority-data = var.ca_data
            server                     = var.server
          }
          name = var.cluster_name
        }
      ]
      contexts = [
        {
          context = {
            cluster = var.cluster_name
            user    = var.cluster_name
          }
          name = var.cluster_name
        }
      ]
      current-context = var.cluster_name
      users = [
        {
          name = var.cluster_name
          user = {
            token = data.kubernetes_secret.istio_reader_token.data.token
          }
        }
      ]
    })
  }

  depends_on = [data.kubernetes_secret.istio_reader_token]
}
