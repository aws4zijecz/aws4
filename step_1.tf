resource "aws_kms_key" "kms_key_1" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "aws4-bucket4" {
  bucket = "aws4-bucket4"
}

resource "aws_s3_bucket_versioning" "aws4-bucket4-versioning" {
  bucket = aws_s3_bucket.aws4-bucket4.id
  versioning_configuration {
    status = "Enabled"
  }
}
