// West VPC
module "vpc_west" {
  providers = {
    aws = aws.west
  }

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "${local.name}-west"
  cidr = local.vpc_cidr

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  private_subnet_names = ["${local.name}-private-1a", "${local.name}-private-1b", "${local.name}-private-1c"]
  public_subnet_names  = ["${local.name}-public-1a", "${local.name}-public-1b", "${local.name}-public-1c"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  map_public_ip_on_launch = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

// Additional security group for cross clusters communication
resource "aws_security_group" "west_cluster_additional_sg" {
  name        = "west_cluster_additional_sg"
  description = "Allow cluster communication"
  vpc_id      = module.vpc_west.vpc_id

  tags = {
    Name = "west_cluster_additional_sg"
  }

  provider = aws.west

}

resource "aws_vpc_security_group_egress_rule" "west_cluster_additional_sg_allow_all_4" {
  security_group_id = aws_security_group.west_cluster_additional_sg.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  provider = aws.west
}

resource "aws_vpc_security_group_egress_rule" "west_cluster_additional_sg_allow_all_6" {
  security_group_id = aws_security_group.west_cluster_additional_sg.id

  ip_protocol = "-1"
  cidr_ipv6   = "::/0"

  provider = aws.west
}

// Asia VPC
module "vpc_asia" {
  providers = {
    aws = aws.asia
  }

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "${local.name}-asia"
  cidr = local.vpc_cidr

  azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  private_subnet_names = ["${local.name}-private-1a", "${local.name}-private-1b", "${local.name}-private-1c"]
  public_subnet_names  = ["${local.name}-public-1a", "${local.name}-public-1b", "${local.name}-public-1c"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  map_public_ip_on_launch = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

# Additional security group for cross clusters communication
resource "aws_security_group" "asia_cluster_additional_sg" {
  name        = "asia_cluster_additional_sg"
  description = "Allow cluster communication"
  vpc_id      = module.vpc_asia.vpc_id

  tags = {
    Name = "asia_cluster_additional_sg"
  }

  provider = aws.asia
}

resource "aws_vpc_security_group_egress_rule" "asia_cluster_additional_sg_allow_all_4" {
  security_group_id = aws_security_group.asia_cluster_additional_sg.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  provider = aws.asia
}

resource "aws_vpc_security_group_egress_rule" "asia_cluster_additional_sg_allow_all_6" {
  security_group_id = aws_security_group.asia_cluster_additional_sg.id

  ip_protocol = "-1"
  cidr_ipv6   = "::/0"

  provider = aws.asia
}
