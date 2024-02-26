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

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_config" {
  bucket = aws_s3_bucket.aws4-bucket4.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_key_1.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
