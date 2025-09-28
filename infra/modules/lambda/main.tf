resource "aws_iam_role" "lambda_exec" {
  name = "lambda-bootstrap-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "redshift_access" {
  name = "LambdaRedshiftDataAccess"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "redshift-data:ExecuteStatement",
        "redshift-data:GetStatementResult"
      ],
      Resource = "*"
    }]
  })
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}"
  output_path = "${path.module}/lambda_bootstrap.zip"
}

resource "aws_lambda_function" "bootstrap" {
  function_name = "lambda-bootstrap-redshift"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  environment {
    variables = {
      WORKGROUP_NAME = var.redshift_workgroup
      DATABASE_NAME  = var.redshift_database
    }
  }
}

resource "null_resource" "invoke_lambda" {
  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.bootstrap.function_name} --payload '{}' response.json"
  }

  depends_on = [aws_lambda_function.bootstrap]
}