output "eastwest_gateway_name" {
  description = "Name of the east-west gateway helm release"
  value       = helm_release.eastwest_gateway.name
}

output "istiod_name" {
  description = "Name of the istiod helm release"
  value       = helm_release.istiod.name
}
