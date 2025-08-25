locals {
  name = "istio"

  cluster_version = "1.33"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    CreatedBy = "Terraform"
  }
}
