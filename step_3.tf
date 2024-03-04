# Create IAM Role with the name "AthenaQueryRole"
# The role is assumed by Athena for executing queries
resource "aws_iam_role" "athena_query_role" {
  name               = "AthenaQueryRole"
  assume_role_policy = templatefile("assume_role_policy.tpl", {}) # This uses a template file for the role's permissions policy.
}

# Define an Athena Workgroup with the name "athena_workgroup"
# Athena workgroups are used to isolate queries for cost tracking purposes
resource "aws_athena_workgroup" "athena_workgroup" {
  name = "athena_workgroup"
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.aws4-bucket4.bucket}/query-results/" # Specifies the S3 bucket where the results of queries executed in the workgroup will be stored
    }
  }
}

# This resource is defining an IAM policy with the name "AthenaS3QueryPolicy"
# This policy will control what actions its attached role (the "AthenaQueryRole") can perform
resource "aws_iam_policy" "athena_s3_query_policy" {
  name = "AthenaS3QueryPolicy"
  policy = templatefile("athena_s3_query_policy.tpl", {
    region         = local.aws_region
    account_id     = local.account_id
    workgroup_name = aws_athena_workgroup.athena_workgroup.name
    bucket_arn     = aws_s3_bucket.aws4-bucket4.arn
    kms_key_arn    = aws_kms_key.kms_key_1.arn
  })
}

# Attach the defined IAM policy to the defined IAM role
resource "aws_iam_role_policy_attachment" "athena_s3_query_attachment" {
  role       = aws_iam_role.athena_query_role.name       # The name of the role to attach the policy to
  policy_arn = aws_iam_policy.athena_s3_query_policy.arn # The ARN of the policy to attach to the role
}

# Create an AWS Glue Catalog Database with the name "athena_database"
resource "aws_glue_catalog_database" "athena_database" {
  name = "athena_database"
}

# Create an AWS Glue Catalog Table with the name "lottery_data"
resource "aws_glue_catalog_table" "athena_table" {
  name          = "lottery_data"
  database_name = aws_glue_catalog_database.athena_database.name

  table_type = "EXTERNAL_TABLE" # Identifies this as an external table pointing to data stored in an S3 bucket

  parameters = { # Import a .csv file with "," delimiter
    "classification"   = "csv"
    "typeOfData"       = "file"
    "delimiter"        = ","
    "columnsOrdered"   = "true"
    "areColumnsQuoted" = "false"
  }

  storage_descriptor {                                                  # Describes the physical storage of this table
    location      = "s3://${aws_s3_bucket.aws4-bucket4.bucket}/dataset" # S3 bucket containing the data
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info { # Defines how to serialize and deserialize the data (SerDe)
      name                  = "SerDeCsv"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = { # Defines parameters for the SerDe such as the separator character used for CSV files
        "separatorChar" = ","
        "quoteChar"     = "\""
        "escapeChar"    = "\\"
      }
    }

    # Define columns in the table (table schema)
    columns {
      name = "draw_date"
      type = "string"
    }

    columns {
      name = "winning_number_1"
      type = "int"
    }

    columns {
      name = "winning_number_2"
      type = "int"
    }

    columns {
      name = "winning_number_3"
      type = "int"
    }

    columns {
      name = "winning_number_4"
      type = "int"
    }

    columns {
      name = "winning_number_5"
      type = "int"
    }

    columns {
      name = "mega_ball"
      type = "int"
    }

    columns {
      name = "multiplier"
      type = "int"
    }
  }

}

# Create an Athena Named Query (aka View) with the name "lottery_data_view"
# It mirrors the original table "lottery_data" and only traslates "draw_date"
# to a "date" format in the database
resource "aws_athena_named_query" "lottery_data_view" {
  name     = "lottery_data_view"
  database = aws_glue_catalog_database.athena_database.name

  query = <<EOF
    CREATE OR REPLACE VIEW lottery_data_view AS
    SELECT
      date_parse(draw_date, '%Y-%m-%d') as draw_date,
      winning_number_1,
      winning_number_2,
      winning_number_3,
      winning_number_4,
      winning_number_5,
      mega_ball,
      multiplier
    FROM
      lottery_data
  EOF
}
