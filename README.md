# aws4

**Hello,**

Clarification: To avoid mentioning the name of the company or `test`, an arbitrary name of `aws4` was chosen to name different resources. It bears no meaning and serves only as a placeholder.

## 0. ENV PREPARATION

To prepare the environment I did the following (manually):
1. register a fresh github account
2. create new git repository
3. install awscli & terraform
4. register a fresh AWS account
5. create an AWS user & group
6. attach group to user
7. generate access key
8. configure awscli
9. copy `policy1.json` to https://us-east-1.console.aws.amazon.com/iamv2/home?region=eu-north-1#/policies/create
10. attach policy to the group
11. init terraform with AWS provider
