resource "aws_cloudformation_stack" "superset_cf" {
  name         = "superset-cf"
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
    SuperSetUserName      = "supersetuser"
    SuperSetUserPassword  = "SuperSet123@"
    WithExample           = "no"
    InstallProphet        = "no"
    ClusterName           = "superset-cf"
    PublicSubnet1         = module.vpc.public_subnets[0]
    PublicSubnet2         = module.vpc.public_subnets[1]
    PrivateSubnet1        = module.vpc.private_subnets[0]
    PrivateSubnet2        = module.vpc.private_subnets[1]
    Vpc                   = module.vpc.vpc_id
    SelfSignedCertificate = local.certificate_data.CertificateArn
  }
  template_url = "https://aws4-bucket5.s3.eu-north-1.amazonaws.com/formation/superset-entrypoint-existing-vpc.template.yaml"
}

data "aws_cloudformation_stack" "stack" {
  name = "superset-cf"
}

output "SupersetConsole" {
  description = "URL of the Superset console"
  value       = data.aws_cloudformation_stack.stack.outputs["SupersetConsole443"]
}
