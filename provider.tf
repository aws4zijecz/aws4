provider "aws" {
  region = local.aws_region
}

locals {
  name       = "superset"
  aws_region = "eu-north-1"
  account_id = "637423491198"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Name = local.name
  }

  # Load certificate ARN from the JSON file
  certificate_data = jsondecode(file("certificate.json"))
}
