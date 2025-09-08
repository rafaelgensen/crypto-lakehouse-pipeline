
# Upload do script
resource "aws_s3_object" "glue_bronze_script" {
  bucket = aws_s3_bucket.glue-scripts.id 
  key    = "glue_job_bronze.py"
  source = "${path.module}/glue_job_bronze.py"
}

# Glue Job
resource "aws_glue_job" "bronze" {
  name     = "coingecko-bronze-etl"
  role_arn = aws_iam_role.glue_bronze_role.arn

  command {
    name            = "gluebronze"
    script_location = "s3://${aws_s3_bucket.glue-scripts.bucket}/glue_job_bronze.py"
    python_version  = "3"
  }

  glue_version = "4.0"
  max_capacity = 2
  description  = "bronze from Coingecko API"

    default_arguments = {
    "--enable-metrics"      = "true"                # send metrics to CloudWatch
    "--TempDir"             = "s3://coingecko-bronze-663354324751/temp/"
  }

}