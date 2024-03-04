# Load array of available AWS zones
data "aws_availability_zones" "available" {}

# External/Public Terraform module for AWS VPC
# Create VPC, private and public subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

# output "public_subnets" {
#   value = module.vpc.public_subnets
# }
# output "private_subnets" {
#   value = module.vpc.private_subnets
# }
# output "vpc" {
#   value = module.vpc
# }
