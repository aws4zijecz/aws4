
# AWS4

**Hello,**

>**NOTE:** Just to clarify: the name `aws4` was chosen as an arbitrary placeholder to name different resources, avoiding any mention of the company or `test`. It bears no meaning beyond this purpose.

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
11. Did the same for `policy2.json`; this policy is solely for CloudFormation and the Apache Partner Program.
12. Initialized Terraform with the AWS provider.

## 1. Defining an S3 Bucket Using KMS Encryption

>**TASK:** _Define an S3 bucket using KMS encryption._

With the environment prepared in step 0, creating the S3 bucket is straightforward. All resources for this operation are in the `step_1.tf` file, which can be found here: <https://github.com/aws4zijecz/aws4/blob/main/step_1.tf>

Three resources are needed for this operation:

1. **The KMS Key:** This is the encryption key that will be used to encrypt the data stored in the S3 bucket. It is created and managed by AWS Key Management Service (KMS).
2. **The S3 Bucket:** This is the storage container where the data will be stored. It is created and managed by Amazon S3.
3. **Server-side Encryption Configuration:** This configuration applies the KMS encryption using the key from step 1 to the bucket from step 2. It ensures that all data stored in the bucket is automatically encrypted using the specified KMS key.

## 2. Synchronizing the Dataset to the S3 Bucket

>**TASK:** _Load public CSV dataset into the created S3 bucket._

After setting up the S3 bucket with KMS encryption, the next task is to populate it with data. For this purpose, a Bash script named `step_2.sync_dataset.bash` is used to download a public CSV dataset from NY.gov and upload it to the AWS S3 bucket only if the local copy is newer than the one already present in the bucket.

The script performs the following functions:

- Downloads the dataset from a specified URL.
- Checks if the downloaded file is newer than the one in the S3 bucket by comparing timestamps.
- Uploads the file to the S3 bucket if the local file is newer, setting custom metadata for the last modified time.
- Cleans up any temporary files created during the process.

### Usage

To execute the script, run the following command in your terminal:

```bash
./step_2.sync_dataset.bash
```

#### Options:

- `-v`: (optional) turns on verbose output
- `-f`: (optional) forces upload disregarding timestamps
- `-h`: (optional) prints script usage and exits

## 3. Create an IAM Role for Athena

> **TASK:** _Create an IAM role with the following permissions:
> a. Ability to use Athena within a specific workgroup (Athena).
> b. Authorization to query the S3 bucket using Athena._

All AWS resources for this part are in `step_3.tf`:

- **"aws_iam_role" "athena_query_role"** - AWS Role for Athena
- **"aws_athena_workgroup" "athena_workgroup"** - Athena Workgroup
- **"aws_iam_policy" "athena_s3_query_policy"** - definition of Policy
- **"aws_iam_role_policy_attachment" "athena_s3_query_attachment"** - attaching the Policy to the Role

- **"aws_glue_catalog_database" "athena_database"** - creation of a Glue Catalog

- **"aws_glue_catalog_table" "athena_table"** - Glue Catalog Table importing the CSV stored in S3 in Step 2

- **"aws_athena_named_query" "lottery_data_view"** - creation of view to map `draw_date` to its actual date instead of type string (see: _Deliverable 5.b.iv_)
To create this view, navigate to <https://eu-north-1.console.aws.amazon.com/athena/home?region=eu-north-1#/query-editor/saved-queries> after the deployment is done and run this query from the console.

## 4. AWS Access Key

>**TASK:** _Create an AWS access key that can assume the IAM role._

Only three resources are needed for this:

- **"aws_iam_user" "aws5"** - The user
- **"aws_iam_user_policy" "user_assume_role_policy"** - Allow role assumption
- **"aws_iam_access_key" "user_access_key"** - Create a key for the user

This also creates two outputs `aws5_key_id` and `aws5_key_secret`. These are sensitive outputs so to access them, run the following commands:

```bash
terraform output --raw aws5_key_id
terraform output --raw aws5_key_secret
```

## 5. Superset Deployment

> **TASK:** _Deploy Superset on your preferred orchestration platform, ensuring internet accessibility.
> a. We recommend using ECS/Fargate/EKS/Hashi-Nomad, Consul, and leveraging public Terraform modules.
> b. Upon deployment, please provide the HTTPS URL for accessing the Superset instance._

Superset is deployed on a VPC created using a public Terraform module _(file: step_5.vpc.tf)_ with AWS CloudFormation _(file: step_5.formation.tf)_. As the template for this is larger than Terraform can support directly, it's stored in an S3 bucket. (See: _Deliverables: Design Decisions_ for details.)

#### Self-Signed Certificate

Prior to the CloudFormation deployment, a self-signed certificate must be uploaded to AWS.

```bash
# Generate a private key
openssl genrsa -out selfsigned.key 2048

# Generate a CSR (Certificate Signing Request)
openssl req -new -key selfsigned.key -out selfsigned.csr

# Generate a Self-Signed Certificate and answer the questions for certificate signing request
openssl x509 -req -days 365 -in selfsigned.csr -signkey selfsigned.key -out selfsigned.crt

# Import the self-signed certificate into AWS Certificate Manager
# Write ARN to 'certificate.json'
aws acm import-certificate --certificate fileb://selfsigned.crt --private-key fileb://selfsigned.key --region eu-north-1 | tee certificate.json
```

Use the commands above for certificate creation and upload or use the `cert.sh` script.

After the deployment is done, the URL of the Superset is in Terraform output `SupersetConsole`.

## 6. Superset DB Connection

> **TASK:** _Configure Superset to be able to query the aforementioned S3 bucket._

After logging into Superset, another sensitive Terraform output is used for the DB connection:

```bash
terraform output --raw db_uri
```

Add Athena as a database using the menu in the top right corner and add datasets from the connected database according to the Superset documentation.

## 7. Dashboard Creation

> **TASK:** _Create a simple dashboard with 2-3 visualizations in Superset connecting to the data in the above S3 bucket._

With datasets loaded, it's up to the user to define his dashboards and charts. For this example, two charts are created:

- A pie chart of **Absolute Multiplier Distribution**.
- A scatter chart with **Time Development of Average Multiplier by Month**.

Dashboard link: <https://supers-loadb-atfqepvm4nif-1538641198.eu-north-1.elb.amazonaws.com/superset/dashboard/1/>

## 8. Time Series Statistics

> **TASK:** _Highlight a few simple statistics about the time series._

- As we can see from the scatter chart, Multiplier mechanics weren't introduced to Mega Lottery until 2011, as the chart shows values of one for any prior dates.
- After the Multiplier was introduced, the average Multiplier aggregated over a month was rising until the end of 2017, but starting in 2018, there was a steep decline.

---

# Deliverables

## 1 - Access Key ID and Secret, 2 - Terraform Plan File, 3 - Git Project Repository, and 4 - Superset Credentials and URL

For deliverables 1, 2, and 4, see attachments in the email.
For Git, this file can be found together with the rest of the project at: <https://github.com/aws4zijecz/aws4/blob/main/README.md>

## 5.a Design Decisions

Many of the design decisions weren't up to me, but did align with what I would do—for example, using Terraform and Git.

### Decisions:

- Use this `README.md` for the Deliverables, to make use of Markdown.
- Use new AWS and Git accounts so they both might easily become Deliverables, if requested.
- Use `policy1.json` instead of a blank `"*"` admin policy to show that even an admin account can be limited for the purposes of its tasks.

### Task Overview:

1. Create a KMS encrypted S3 bucket - straightforward creation in Terraform.
2. Load CSV to S3 - I decided to write a BASH script for this mainly to present my scripting skills.
3. and 4. Create IAM resources - straightforward creation in Terraform.
5. Superset Deployment - here were several paths I could have chosen:
    - EKS - considered due to my familiarity with OKE.
    - Pure Terraform - considered and tried for granular control over resources.
    - Public Terraform modules - used for VPC creation as a PoC, otherwise discarded for unsupported `entryPoint` and poor volume management.
    - CloudFormation Partner Solution - chosen, but modified to support HTTPS.

## 5.b SQL Queries

### 5.b.i - Find the top 5 common Winning Numbers

Below there are two approaches to this task. Join all numbers and count frequency on all of them together, or count frequency on each column separately, join them afterward, and sum the frequencies.
In this case, the first approach is faster (due to the number distribution), but for other or larger sets, the second approach might become more resource and time-effective.

> **WARN:** These are not _"true"_ top 5 numbers, as if any number shares the fifth place, it will be omitted. To include all numbers that share the fifth place see _Deliverable 5.b.iii - Top 5 Mega Ball numbers_, which shows how to solve this.

#### Approach 1

```sql
SELECT num, COUNT(*) as frequency
FROM (
    SELECT winning_number_1 AS num FROM lottery_data
    UNION ALL
    SELECT winning_number_2 AS num FROM lottery_data
    UNION ALL
    SELECT winning_number_3 AS num FROM lottery_data
    UNION ALL
    SELECT winning_number_4 AS num FROM lottery_data
    UNION ALL
    SELECT winning_number_5 AS num FROM lottery_data
) AS combined_table
GROUP BY num
ORDER BY frequency DESC
LIMIT 5;
```

#### Approach 2

```sql
SELECT num, SUM(frequency) as total_frequency
FROM (
    SELECT winning_number_1 AS num, COUNT(*) as frequency
    FROM lottery_data GROUP BY winning_number_1
    UNION ALL
    SELECT winning_number_2 AS num, COUNT(*) as frequency
    FROM lottery_data GROUP BY winning_number_2
    UNION ALL
    SELECT winning_number_3 AS num, COUNT(*) as frequency
    FROM lottery_data GROUP BY winning_number_3
    UNION ALL
    SELECT winning_number_4 AS num, COUNT(*) as frequency
    FROM lottery_data GROUP BY winning_number_4
    UNION ALL
    SELECT winning_number_5 AS num, COUNT(*) as frequency
    FROM lottery_data GROUP BY winning_number_5
) AS combined_table
GROUP BY num
ORDER BY total_frequency DESC
LIMIT 5;
```

### 5.b.ii - Average Multiplier

```sql
SELECT AVG(multiplier) AS "Average Multiplier"
FROM "athena_database"."lottery_data"
```

### 5.b.iii - Identify the top 5 Mega Ball Numbers

> **NOTE:** This query might return more than 5 numbers if any numbers share the fifth place.
```sql
SELECT 
    mega_ball, 
    COUNT(*) as count
FROM 
    lottery_data
GROUP BY 
    mega_ball
ORDER BY
    count DESC
LIMIT 5
WITH frequency AS (
    SELECT 
        mega_ball, 
        COUNT(*) as count,
        ROW_NUMBER() OVER (ORDER BY count(*) DESC) AS rownum
    FROM 
        lottery_data
    GROUP BY 
        mega_ball
    ORDER BY
        count DESC
)
    SELECT 
        mega_ball,
        count
    FROM 
        frequency
    WHERE count>=(SELECT count FROM frequency WHERE rownum=5)
```

### 5.b.iv - How many of the lotteries were drawn on a weekday vs weekend

#### Approach 1

Mega Lottery is drawn on Tuesdays and Fridays, meaning we can simply count the number of entries.

```sql
SELECT
    COUNT(*) AS tuesdays_and_fridays,
    0 AS weekends
FROM lottery_data;
```

#### Approach 2

We can prove this by actually mapping `draw_date` to days of the week.

> **NOTE:** This query uses `lottery_data_view` instead of `lottery_data` table, as we prepared `draw_date` as a date format in Terraform and console (see step 3, Terraform resource `aws_athena_named_query`).

```sql
SELECT 
    SUM(CASE WHEN CAST(extract(dow FROM draw_date) AS integer)
	    BETWEEN 1 AND 5 THEN 1 ELSE 0 END) AS weekdays,
    SUM(CASE WHEN CAST(extract(dow FROM draw_date) AS integer)
	    IN (0, 6) THEN 1 ELSE 0 END) AS weekends
FROM lottery_data_view;
```