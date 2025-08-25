output "root_cert" {
  description = "Root CA certificate"
  value       = tls_self_signed_cert.ca.cert_pem
  sensitive   = false
}

output "certs" {
  description = "Intermediate certificates for each cluster"
  value = {
    for k, v in tls_locally_signed_cert.cert : k => v.cert_pem
  }
  sensitive = false
}

output "keys" {
  description = "Private keys for each cluster's intermediate certificate"
  value = {
    for k, v in tls_private_key.cert : k => v.private_key_pem
  }
  sensitive = true
}
