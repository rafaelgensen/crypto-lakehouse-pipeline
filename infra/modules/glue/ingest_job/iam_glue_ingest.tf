# 1. Política para acessar S3
resource "aws_iam_policy" "glue_ingest_s3" {
  name   = "glue-ingest-s3"
  policy = file("${path.module}/policy_glue_ingest.json")
}

# 2. Política para acessar o parâmetro no SSM
resource "aws_iam_policy" "glue_ingest_ssm" {
  name        = "glue-ingest-ssm"
  description = "Permite o Glue acessar o parâmetro da API no SSM"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter"
        ],
        Resource = "arn:aws:ssm:us-east-1:663354324751:parameter/coing-gecko/api_key"
      }
    ]
  })
}

# 3. Criar a role para o Glue Job
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

# 4. Anexar as políticas (S3 e SSM) à role
resource "aws_iam_role_policy_attachment" "glue_ingest_attach_s3" {
  role       = aws_iam_role.glue_ingest_role.name
  policy_arn = aws_iam_policy.glue_ingest_s3.arn
}

resource "aws_iam_role_policy_attachment" "glue_ingest_attach_ssm" {
  role       = aws_iam_role.glue_ingest_role.name
  policy_arn = aws_iam_policy.glue_ingest_ssm.arn
}