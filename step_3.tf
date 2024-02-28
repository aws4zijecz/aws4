# Define the IAM role that will be assumed by Athena
resource "aws_iam_role" "athena_query_role" {
  name               = "AthenaQueryRole"
  assume_role_policy = templatefile("assume_role_policy.tpl", {})
}

# Define the IAM policy that gives the role permissions to operate with Athena and S3
resource "aws_iam_policy" "athena_s3_query_policy" {
  name = "AthenaS3QueryPolicy"
  policy = templatefile("athena_s3_query_policy.tpl", {
    # Variables for the S3 bucket and KMS key ARNs
    bucket_arn  = aws_s3_bucket.aws4-bucket4.arn,
    kms_key_arn = aws_kms_key.kms_key_1.arn
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "athena_s3_query_attachment" {
  role       = aws_iam_role.athena_query_role.name
  policy_arn = aws_iam_policy.athena_s3_query_policy.arn
}
