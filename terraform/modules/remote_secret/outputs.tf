output "remote_secret_name" {
  description = "Name of the remote secret created"
  value       = kubernetes_secret.remote_secret.metadata[0].name
}
