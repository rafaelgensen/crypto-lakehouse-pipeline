# Bucket para armazenar scripts do Glue
resource "aws_s3_bucket" "glue-scripts" {
  bucket = "coingecko-glue-scripts-663354324751"
}

# Access policy
resource "aws_s3_bucket_policy" "glue-scripts" {
  bucket = aws_s3_bucket.glue-scripts.id
  policy = file("${path.module}/policy_scripts_bucket.json")
}

# Upload do script
resource "aws_s3_object" "glue_silver_script" {
  bucket = aws_s3_bucket.glue-scripts.id 
  key    = "glue_job_silver.py"
  source = "${path.module}/glue_job_silver.py"
}

# Glue Job
resource "aws_glue_job" "silver" {
  name     = "coingecko-silver-etl"
  role_arn = aws_iam_role.glue_silver_role.arn

  command {
    name            = "gluesilver"
    script_location = "s3://${aws_s3_bucket.glue-scripts.bucket}/glue_job_silver.py"
    python_version  = "3"
  }

  glue_version = "4.0"
  max_capacity = 2
  description  = "Bronze to Silver"

    default_arguments = {
    "--enable-metrics"      = "true"                # send metrics to CloudWatch
    "--TempDir"             = "s3://coingecko-silver-663354324751/temp/"
  }

}