provider "aws" {
  alias  = "west"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "asia"
  region = "ap-southeast-1"
}


provider "kubernetes" {
  alias                  = "west"
  host                   = module.eks_west.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_west.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_west.cluster_name]
  }
}

provider "kubernetes" {
  alias                  = "asia"
  host                   = module.eks_asia.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_asia.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_asia.cluster_name]
  }
}


provider "helm" {
  alias = "west"
  kubernetes = {
    host                   = module.eks_west.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_west.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_west.cluster_name]
    }
  }
}

provider "helm" {
  alias = "asia"
  kubernetes = {
    host                   = module.eks_asia.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_asia.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_asia.cluster_name]
    }
  }
}

provider "kubectl" {
  alias                  = "west"
  host                   = module.eks_west.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_west.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_west.cluster_name]
  }
}

provider "kubectl" {
  alias                  = "asia"
  host                   = module.eks_asia.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_asia.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_asia.cluster_name]
  }
}
