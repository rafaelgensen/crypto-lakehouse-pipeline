# IAM Role allowing EventBridge to invoke the Step Function
resource "aws_iam_role" "eventbridge_invoke_stepfunctions" {
  name = "EventBridgeInvokeStepFunctions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "events.amazonaws.com"  # Principal for EventBridge
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
      Action   = "states:StartExecution",     # Required to start Step Function
      Resource = aws_sfn_state_machine.glue_etl_pipeline.arn
    }]
  })
}