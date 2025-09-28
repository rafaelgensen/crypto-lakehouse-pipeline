# Upload do script
resource "aws_s3_object" "glue_bronze_script" {
  bucket      = "coingecko-glue-scripts-663354324751"
  key         = "glue_job_bronze.py"
  source      = "${path.module}/glue_job_bronze.py"
  source_hash = filebase64sha256("${path.module}/glue_job_bronze.py")
}

# Glue Job
resource "aws_glue_job" "bronze" {
  depends_on = [aws_s3_object.glue_bronze_script]

  name     = "coingecko-bronze-etl"
  role_arn = aws_iam_role.glue_bronze_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://coingecko-glue-scripts-663354324751/glue_job_bronze.py"
    python_version  = "3"
  }

  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  description       = "Staging to Bronze"

  default_arguments = {
    "--enable-metrics"     = "true"
    "--TempDir"            = "s3://coingecko-bronze-663354324751/temp/"
    "--dq-results-path"    = "s3://coingecko-bronze-663354324751/dq-results/"
    "--job-language"       = "python"
  }
}
