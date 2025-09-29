data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/src"  # Ajuste aqui para a pasta do seu código Python (onde está o handler.py)
  output_path = "${path.module}/lambda_bootstrap.zip"
}

resource "aws_iam_role_policy" "lambda_glue_access" {
  name = "LambdaGlueCatalogAccess"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "glue:CreateDatabase",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:DeleteTable",
          "glue:BatchCreatePartition",
          "glue:GetPartitions"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::coingecko-gold-663354324751",
          "arn:aws:s3:::coingecko-gold-663354324751/*",
          "arn:aws:s3:::coingecko-silver-663354324751",
          "arn:aws:s3:::coingecko-silver-663354324751/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "bootstrap" {
  function_name = "lambda-bootstrap-glue"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  environment {
    variables = {
      S3_BUCKET_SILVER = "coingecko-silver-663354324751"
      S3_BUCKET_GOLD   = "coingecko-gold-663354324751"
    }
  }
}
