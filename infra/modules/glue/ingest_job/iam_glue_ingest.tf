# 1. Criar a política gerenciada
resource "aws_iam_policy" "glue_ingest_s3" {
  name   = "glue-ingest-s3"
  policy = file("${path.module}/policy_glue_ingest.json")
}

# 2. Criar a role
resource "aws_iam_role" "glue_ingest_role" {
  name = "glue-ingest-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "glue.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# 3. Fazer o attach da política à role
resource "aws_iam_role_policy_attachment" "glue_ingest_attach" {
  role       = aws_iam_role.glue_ingest_role.name
  policy_arn = aws_iam_policy.glue_ingest_s3.arn
}