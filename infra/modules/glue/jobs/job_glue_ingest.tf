

# Upload do script
resource "aws_s3_object" "glue_ingest_script" {
  bucket = aws_s3_bucket.glue_scripts.id 
  key    = "glue_job_ingest.py"
  source = "${path.module}/../scripts/glue_job_ingest.py"
}

# Glue Job
resource "aws_glue_job" "ingest" {
  name     = "glue-ingest"
  role_arn = aws_iam_role.glue_ingest_role.arn

  command {
    name            = "glueingest"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/glue_job_ingest.py"
    python_version  = "3"
  }

  glue_version = "4.0"
  max_capacity = 2
  description  = "Ingest from Coingecko API"

    default_arguments = {
    "--enable-metrics"      = "true"                # send metrics to CloudWatch
    "--TempDir"             = "s3://coingecko-staging-663354324751/temp/"
  }

}