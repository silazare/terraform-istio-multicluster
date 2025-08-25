## Requirements

| Name | Version |
|------|---------|
| helm | ~> 3.0 |
| kubectl | ~> 2.1 |
| kubernetes | ~> 2.38 |
| null | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| helm | ~> 3.0 |
| kubectl | ~> 2.1 |
| kubernetes | ~> 2.38 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.eastwest_gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.cross_network_gateway](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.expose_istiod](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.peer_authentication_strict](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.istio_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.mtls_namespaces](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.cacerts](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ca\_root | Root CA certificate | `string` | n/a | yes |
| cert | Intermediate certificate for this cluster | `string` | n/a | yes |
| cluster\_name | Name of the cluster | `string` | n/a | yes |
| istio\_version | Istio chart version | `string` | n/a | yes |
| key | Private key for this cluster's intermediate certificate | `string` | n/a | yes |
| mesh\_id | Mesh ID for multi-cluster setup | `string` | n/a | yes |
| mtls\_namespaces | Namespaces to configure with strict mTLS PeerAuthentication | ```map(object({ peer_auth_name = string }))``` | `{}` | no |
| network | Network name for this cluster | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| eastwest\_gateway\_name | Name of the east-west gateway helm release |
| istiod\_name | Name of the istiod helm release |
