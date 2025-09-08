
# Upload do script
resource "aws_s3_object" "glue_gold_script" {
  bucket = "coingecko-glue-scripts-663354324751"
  key    = "glue_job_gold.py"
  source = "${path.module}/glue_job_gold.py"
}

# Glue Job
resource "aws_glue_job" "gold" {
  name     = "coingecko-gold-etl"
  role_arn = aws_iam_role.glue_gold_role.arn

  command {
    name            = "gluegold"
    script_location = "s3://coingecko-glue-scripts-663354324751/glue_job_gold.py"
    python_version  = "3"
  }

  glue_version = "4.0"
  max_capacity = 2
  description  = "Silver to Gold"

    default_arguments = {
    "--enable-metrics"      = "true"                # send metrics to CloudWatch
    "--TempDir"             = "s3://coingecko-gold-663354324751/temp/"
  }

}