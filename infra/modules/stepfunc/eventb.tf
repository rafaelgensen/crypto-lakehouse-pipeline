# EventBridge rule to trigger the Step Function once per week on Fridays at 19:00 UTC
resource "aws_cloudwatch_event_rule" "weekly_etl_friday" {
  name        = "weekly-etl-on-friday"
  description = "Triggers Step Function every Friday at 19:00 UTC"

  # AWS cron expression format: cron(Minutes Hours Day-of-month Month Day-of-week Year)
  schedule_expression = "cron(0 19 ? * 6 *)"
  # └─ This means:
  #    minute = 0
  #    hour   = 19 (7:00 PM UTC)
  #    day-of-month = ? (ignored)
  #    month = * (every month)
  #    day-of-week = 6 (Friday)
  #    year = * (every year)
}

# EventBridge target that invokes the Step Function
resource "aws_cloudwatch_event_target" "weekly_target" {
  rule     = aws_cloudwatch_event_rule.weekly_etl_friday.name       # Link to the rule above
  arn      = aws_sfn_state_machine.glue_etl_pipeline.arn            # The Step Function to invoke
  role_arn = aws_iam_role.eventbridge_invoke_stepfunctions.arn      # IAM role with states:StartExecution permission
}