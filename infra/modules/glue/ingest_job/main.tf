
# Bucket para armazenar scripts do Glue
resource "aws_s3_bucket" "glue-scripts" {
  bucket = "coingecko-glue-scripts-663354324751"
}

# Access policy
resource "aws_s3_bucket_policy" "glue-scripts" {
  bucket = aws_s3_bucket.glue-scripts.id
  policy = file("${path.module}/policies/policy_scripts_bucket.json")
}