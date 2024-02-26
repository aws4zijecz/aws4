# AWS4

**Hello,**

Just to clarify: The name `aws4` was chosen as an arbitrary placeholder to name different resources, avoiding any mention of the company or `test`. It bears no meaning beyond this purpose.

## 0. Environment Preparation

To prepare the environment, I performed the following steps manually:
1. Registered a fresh GitHub account.
2. Created a new Git repository.
3. Installed AWS CLI and Terraform.
4. Registered a fresh AWS account.
5. Created an AWS user and group.
6. Attached the group to the user.
7. Generated an access key.
8. Configured AWS CLI.
9. Using `policy1.json`, created a policy named `policy1` in the AWS Console.
10. Attached the policy to the group.
11. Initialized Terraform with the AWS provider.

## 1. Defining an S3 Bucket Using KMS Encryption

With the environment prepared in step 0, creating the S3 bucket is straightforward. All resources for this operation are in the `step_1.tf` file, which can be found here: https://github.com/aws4zijecz/aws4/blob/main/step_1.tf

Three resources are needed for this operation:

1. **The KMS Key:** This is the encryption key that will be used to encrypt the data stored in the S3 bucket. It is created and managed by AWS Key Management Service (KMS).

2. **The S3 Bucket:** This is the storage container where the data will be stored. It is created and managed by Amazon S3.

3. **Server-side Encryption Configuration:** This configuration applies the KMS encryption using the key from step 1 to the bucket from step 2. It ensures that all data stored in the bucket is automatically encrypted using the specified KMS key.
