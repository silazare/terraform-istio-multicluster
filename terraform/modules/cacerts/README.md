## Requirements

| Name | Version |
|------|---------|
| tls | ~> 4.1 |

## Providers

| Name | Version |
|------|---------|
| tls | ~> 4.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [tls_cert_request.cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| clusters | List of cluster names to generate certificates for | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| certs | Intermediate certificates for each cluster |
| keys | Private keys for each cluster's intermediate certificate |
| root\_cert | Root CA certificate |
