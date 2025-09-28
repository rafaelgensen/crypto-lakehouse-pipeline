# Upload do script
resource "aws_s3_object" "glue_gold_script" {
  bucket      = "coingecko-glue-scripts-663354324751"
  key         = "glue_job_gold.py"
  source      = "${path.module}/glue_job_gold.py"
  source_hash = filebase64sha256("${path.module}/glue_job_gold.py")
}

# Glue Job
resource "aws_glue_job" "gold" {
  depends_on = [aws_s3_object.glue_gold_script]

  name     = "coingecko-gold-etl"
  role_arn = aws_iam_role.glue_gold_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://coingecko-glue-scripts-663354324751/glue_job_gold.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  description       = "Silver to Gold"

  default_arguments = {
    "--enable-metrics" = "true"
    "--TempDir"        = "s3://coingecko-gold-663354324751/temp/"
    "--job-language"   = "python"
  }
}
