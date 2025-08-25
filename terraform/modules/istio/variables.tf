variable "network" {
  description = "Network name for this cluster"
  type        = string
}

variable "mesh_id" {
  description = "Mesh ID for multi-cluster setup"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "ca_root" {
  description = "Root CA certificate"
  type        = string
}

variable "cert" {
  description = "Intermediate certificate for this cluster"
  type        = string
}

variable "key" {
  description = "Private key for this cluster's intermediate certificate"
  type        = string
  sensitive   = true
}

variable "istio_version" {
  description = "Istio chart version"
  type        = string
}

variable "mtls_namespaces" {
  description = "Namespaces to configure with strict mTLS PeerAuthentication"
  type = map(object({
    peer_auth_name = string
  }))
  default = {}
}
