// West EKS Cluster
module "eks_west" {
  providers = {
    aws = aws.west
  }

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = "${local.name}-west"
  cluster_version = local.cluster_version

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  enable_efa_support = true

  vpc_id     = module.vpc_west.vpc_id
  subnet_ids = module.vpc_west.private_subnets

  eks_managed_node_groups = {
    default = {
      name           = "${local.name}-default"
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      # Use all private subnets for default node group
      subnet_ids = module.vpc_west.private_subnets

      min_size     = 3
      max_size     = 3
      desired_size = 3

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 32
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      }

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      labels = {
        "node.kubernetes.io/role" = "regular"
      }
    }
  }

  # SG Rule for nodes in cluster 2 to be able to reach to the cluster1 control plane
  cluster_security_group_additional_rules = {
    ingress_allow_from_other_cluster = {
      description              = "Access EKS from EC2 instances in other cluster."
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.west_cluster_additional_sg.id
    }
  }

  #  EKS K8s API cluster needs to be able to talk with the EKS worker nodes with port 15017/TCP and 15012/TCP which is used by Istio
  #  Istio in order to create sidecar needs to be able to communicate with webhook and for that network passage to EKS is needed.
  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15443 = {
      description                   = "Istio Cross Network Gateway"
      protocol                      = "TCP"
      from_port                     = 15443
      to_port                       = 15443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_80 = {
      description                   = "Kubernetes rest client"
      protocol                      = "TCP"
      from_port                     = 80
      to_port                       = 80
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  tags = merge(local.tags, {
    "kubernetes.io/cluster/${local.name}" = "owned"
  })
}


// Asia EKS Cluster
module "eks_asia" {
  providers = {
    aws = aws.asia
  }

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = "${local.name}-asia"
  cluster_version = local.cluster_version

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  enable_efa_support = true

  vpc_id     = module.vpc_asia.vpc_id
  subnet_ids = module.vpc_asia.private_subnets

  eks_managed_node_groups = {
    default = {
      name           = "${local.name}-default"
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      # Use all private subnets for default node group
      subnet_ids = module.vpc_asia.private_subnets

      min_size     = 3
      max_size     = 3
      desired_size = 3

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 32
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      }

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      labels = {
        "node.kubernetes.io/role" = "regular"
      }
    }
  }

  # SG Rule for nodes in cluster 2 to be able to reach to the cluster1 control plane
  cluster_security_group_additional_rules = {
    ingress_allow_from_other_cluster = {
      description              = "Access EKS from EC2 instances in other cluster."
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.asia_cluster_additional_sg.id
    }
  }

  #  EKS K8s API cluster needs to be able to talk with the EKS worker nodes with port 15017/TCP and 15012/TCP which is used by Istio
  #  Istio in order to create sidecar needs to be able to communicate with webhook and for that network passage to EKS is needed.
  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15443 = {
      description                   = "Istio Cross Network Gateway"
      protocol                      = "TCP"
      from_port                     = 15443
      to_port                       = 15443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_80 = {
      description                   = "Kubernetes rest client"
      protocol                      = "TCP"
      from_port                     = 80
      to_port                       = 80
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  tags = merge(local.tags, {
    "kubernetes.io/cluster/${local.name}" = "owned"
  })
}
