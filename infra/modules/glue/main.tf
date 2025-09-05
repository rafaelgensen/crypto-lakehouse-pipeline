
# Upload do script
resource "aws_s3_object" "glue_bronze_script" {
  bucket = aws_s3_bucket.glue_scripts.id
  key    = "glue_job_bronze.py"
  source = "${path.module}/src/glue_job_bronze.py"
}

# Glue Job
resource "aws_glue_job" "bronze" {
  name     = "glue-bronze"
  role_arn = aws_iam_role.glue_bronze_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/glue_job_bronze.py"
    python_version  = "3"
  }

  glue_version = "4.0"
  max_capacity = 2
  description  = "Transformação Bronze para Coingecko"

}