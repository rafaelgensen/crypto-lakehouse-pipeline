resource "aws_sfn_state_machine" "glue_etl_pipeline" {
  name     = "coingecko-etl-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

definition = jsonencode({
  Comment = "ETL Pipeline: Glue Ingest -> (Bronze + Lambda) -> Silver -> Gold",
  StartAt = "GlueJobBIngest",
  States = {
    GlueJobBIngest = {
      Type       = "Task",
      Resource   = "arn:aws:states:::glue:startJobRun.sync",
      Parameters = {
        JobName = "coingecko-ingest-etl"
      },
      Next = "ParallelBronzeAndLambda",
      Catch = [{
        ErrorEquals = ["States.ALL"],
        ResultPath  = "$.error",
        Next        = "FailState"
      }]
    },
    
    ParallelBronzeAndLambda = {
      Type = "Parallel",
      Branches = [
        {
          StartAt = "GlueJobBronze",
          States = {
            GlueJobBronze = {
              Type       = "Task",
              Resource   = "arn:aws:states:::glue:startJobRun.sync",
              Parameters = {
                JobName = "coingecko-bronze-etl"
              },
              End = true,
              Catch = [{
                ErrorEquals = ["States.ALL"],
                ResultPath  = "$.error",
                Next        = "FailState"
              }]
            }
          }
        },
        {
          StartAt = "LambdaBootstrap",
          States = {
            LambdaBootstrap = {
              Type       = "Task",
              Resource   = "arn:aws:states:::lambda:invoke",
              Parameters = {
                FunctionName = var.lambda_function_arn,
                Payload = {
                  action = "create_schemas"
                }
              },
              End = true,
              Catch = [{
                ErrorEquals = ["States.ALL"],
                ResultPath  = "$.error",
                Next        = "FailState"
              }]
            }
          }
        }
      ],
      Next = "GlueJobSilver"
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
