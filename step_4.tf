# Define the IAM user that will assume the role
resource "aws_iam_user" "aws5" {
  name = "aws5"
}

# Attach a policy to the IAM user that allows assuming the Athena query role
resource "aws_iam_user_policy" "user_assume_role_policy" {
  name = "UserAssumeAthenaRolePolicy"
  user = aws_iam_user.aws5.name
  policy = templatefile("user_assume_role_policy.tpl", {
    role_arn = aws_iam_role.athena_query_role.arn
  })
}

# Create an access key for the IAM user
resource "aws_iam_access_key" "user_access_key" {
  user = aws_iam_user.aws5.name
}

# Output the access key and secret
output "aws5_key_id" {
  value     = aws_iam_access_key.user_access_key.id
  sensitive = true
}

output "aws5_key_secret" {
  value     = aws_iam_access_key.user_access_key.secret
  sensitive = true
}
