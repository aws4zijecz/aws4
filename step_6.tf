# Define new IAM user for Superset
resource "aws_iam_user" "aws6" {
  name = "aws6"
}

# Create an access key for the IAM user
resource "aws_iam_access_key" "superset_user_access_key" {
  user = aws_iam_user.aws6.name
}

# Attach policy to the user
resource "aws_iam_user_policy" "superset_user_athena_s3_query_policy" {
  name   = "UserAthenaS3QueryPolicy"
  user   = aws_iam_user.aws6.name
  policy = data.aws_iam_policy_document.superset_athena_s3_query_policy.json
}

# Policy document instead of a template
data "aws_iam_policy_document" "superset_athena_s3_query_policy" {
  statement {
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:ListNamedQueries",
      "athena:ListWorkGroups",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "glue:GetTable",
      "glue:GetDatabases",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      "arn:aws:athena:${local.aws_region}:${local.account_id}:workgroup/${aws_athena_workgroup.athena_workgroup.name}",
      "arn:aws:glue:${local.aws_region}:${local.account_id}:catalog",
      "${aws_s3_bucket.aws4-bucket4.arn}",
      "${aws_s3_bucket.aws4-bucket4.arn}/*",
      "${aws_kms_key.kms_key_1.arn}",
    ]
  }
  statement {
    actions = [
      "athena:GetQueryExecution",
      "athena:List*",
      "glue:GetDatabases",
      "s3:GetBucketLocation",
    ]
    resources = [
      #   "arn:aws:athena:::*",
      #   "arn:aws:glue:::*",
      #   "arn:aws:s3:::*",
      "*"
    ]
  }
}

# Print uri to put
output "db_uri" {
  value     = "awsathena+rest://${aws_iam_access_key.superset_user_access_key.id}:${aws_iam_access_key.superset_user_access_key.secret}@athena.eu-north-1.amazonaws.com:443/athena_database?s3_staging_dir=s3://aws4-bucket4/query-results/&work_group=athena_workgroup"
  sensitive = true
}
