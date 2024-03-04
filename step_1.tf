# Create an AWS KMS (Key Management Service) Key with a description and a 10 day window for deletion
resource "aws_kms_key" "kms_key_1" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

# Create an AWS S3 (Simple Storage Service) Bucket with the name "aws4-bucket4"
resource "aws_s3_bucket" "aws4-bucket4" {
  bucket = "aws4-bucket4"
}

# Define server-side encryption configuration for the S3 bucket created above
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_config" {
  bucket = aws_s3_bucket.aws4-bucket4.id # The bucket to apply this configuration to

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_key_1.arn # The ARN of the KMS key used for encryption
      sse_algorithm     = "aws:kms"                 # Specify KMS as the type of server-side encryption to use
    }
  }
}
