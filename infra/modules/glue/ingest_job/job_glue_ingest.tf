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
resource "aws_s3_object" "glue_ingest_script" {
  bucket = aws_s3_bucket.glue-scripts.id 
  key    = "glue_job_ingest.py"
  source = "${path.module}/glue_job_ingest.py"
}

# Glue Job
resource "aws_glue_job" "ingest" {
  name     = "coingecko-ingest-etl"
  role_arn = aws_iam_role.glue_ingest_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue-scripts.bucket}/glue_job_ingest.py"
    #script_location = "s3://coingecko-glue-scripts-663354324751/glue_job_ingest.py"
    python_version  = "3"
  }

  glue_version = "5.0"
  worker_type = "G.1X"
  number_of_workers = 2
  description  = "Ingest from Coingecko API"
  

    default_arguments = {
    "--enable-metrics"      = "true"                # send metrics to CloudWatch
    "--TempDir"             = "s3://coingecko-staging-663354324751/temp/"
    "--job-language"   = "python"
  }

}