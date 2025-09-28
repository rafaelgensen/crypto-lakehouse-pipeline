# IAM Role para Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "StepFunctionsGlueExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

# Attach políticas necessárias para Glue, Logs e Step Functions
resource "aws_iam_role_policy_attachment" "step_functions_glue_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "step_functions_basic_execution" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

# Política inline para invocar o Lambda (necessário para chamar o Lambda dentro do Step Function)
resource "aws_iam_role_policy" "step_functions_lambda_invoke" {
  name = "StepFunctionsLambdaInvokePolicy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "lambda:InvokeFunction",
      Resource = aws_lambda_function.bootstrap.arn
    }]
  })
}

# Máquina de estado Step Functions
resource "aws_sfn_state_machine" "glue_etl_pipeline" {
  name     = "coingecko-etl-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "ETL Pipeline: Glue Ingest -> Bronze -> Lambda Bootstrap -> Silver -> Gold",
    StartAt = "GlueJobBIngest",
    States = {
      GlueJobBIngest = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "coingecko-ingest-etl"
        },
        Next       = "GlueJobBronze",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "FailState"
        }]
      },
      GlueJobBronze = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "coingecko-bronze-etl"
        },
        Next       = "LambdaBootstrapSchemas",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "FailState"
        }]
      },
      LambdaBootstrapSchemas = {
        Type = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = aws_lambda_function.bootstrap.arn,
          Payload = {
            action = "create_schemas"
          }
        },
        Next = "GlueJobSilver",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath = "$.error",
          Next = "FailState"
        }]
      },
      GlueJobSilver = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "coingecko-silver-etl"
        },
        Next       = "GlueToGold",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "FailState"
        }]
      },
      GlueToGold = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "coingecko-gold-etl"
        },
        End = true,
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "FailState"
        }]
      },
      FailState = {
        Type    = "Fail",
        Cause   = "ETL Job Failed",
        Error   = "JobExecutionError"
      }
    }
  })

  type = "STANDARD"
}