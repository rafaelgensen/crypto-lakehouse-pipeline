# IAM Role allowing EventBridge to invoke the Step Function
resource "aws_iam_role" "eventbridge_invoke_stepfunctions" {
  name = "EventBridgeInvokeStepFunctions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

# Inline policy granting permission to start executions
resource "aws_iam_role_policy" "eventbridge_stepfunc_policy" {
  name = "EventBridgeInvokeStepFuncPolicy"
  role = aws_iam_role.eventbridge_invoke_stepfunctions.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "states:StartExecution",
      Resource = aws_sfn_state_machine.glue_etl_pipeline.arn
    }]
  })
}

# IAM Role for Step Functions itself
resource "aws_iam_role" "step_functions_role" {
  name = "StepFunctionsGlueExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach necessary managed policies to Step Functions role
resource "aws_iam_role_policy_attachment" "step_functions_glue_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "step_functions_basic_execution" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

# Custom inline policy to allow Step Function to invoke Lambda
resource "aws_iam_role_policy" "step_functions_lambda_invoke" {
  name = "StepFunctionInvokeLambda"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "lambda:InvokeFunction"
      ],
      Resource = var.lambda_function_arn
    }]
  })
}