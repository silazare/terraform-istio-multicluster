variable "cluster_name" {
  description = "Name of the cluster to create remote secret for"
  type        = string
}

variable "ca_data" {
  description = "Base64 encoded CA certificate data"
  type        = string
}

variable "server" {
  description = "Kubernetes API server endpoint"
  type        = string
}
