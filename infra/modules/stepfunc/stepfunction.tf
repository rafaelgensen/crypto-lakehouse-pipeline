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

resource "aws_iam_role_policy_attachment" "step_functions_glue_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "step_functions_basic_execution" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

resource "aws_iam_role_policy" "step_functions_lambda_invoke" {
  name = "StepFunctionsInvokeLambda"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "lambda:InvokeFunction"
        ],
        Resource = var.lambda_function_arn
      }
    ]
  })
}

resource "aws_sfn_state_machine" "glue_etl_pipeline" {
  name     = "coingecko-etl-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "ETL Pipeline: Glue Ingest -> Bronze -> Bootstrap Lambda -> Silver -> Gold",
    StartAt = "GlueJobBIngest",
    States = {
      GlueJobBIngest = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "coingecko-ingest-etl"
        },
        Next = "GlueJobBronze",
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
        Next = "LambdaBootstrap",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "FailState"
        }]
      },
      LambdaBootstrap = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = var.lambda_function_arn,
          Payload = {
            action = "create_schemas"
          }
        },
        Next = "GlueJobSilver",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "FailState"
        }]
      },
      GlueJobSilver = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = "coingecko-silver-etl"
        },
        Next = "GlueToGold",
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
        Type  = "Fail",
        Cause = "ETL Job Failed",
        Error = "JobExecutionError"
      }
    }
  })

  type = "STANDARD"
}