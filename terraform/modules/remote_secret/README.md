## Requirements

| Name | Version |
|------|---------|
| kubernetes | ~> 2.38 |

## Providers

| Name | Version |
|------|---------|
| kubernetes.local | ~> 2.38 |
| kubernetes.remote | ~> 2.38 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.istio_reader](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.istio_reader](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_secret.istio_reader_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.remote_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.istio_reader](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_secret.istio_reader_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ca\_data | Base64 encoded CA certificate data | `string` | n/a | yes |
| cluster\_name | Name of the cluster to create remote secret for | `string` | n/a | yes |
| server | Kubernetes API server endpoint | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| remote\_secret\_name | Name of the remote secret created |
