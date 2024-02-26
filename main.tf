provider "aws" {
    region = "eu-north-1"
}

resource "aws_kms_key" "kms_key_1" {
    description             = "KMS key for S3 bucket encryption"
    deletion_window_in_days = 10
}