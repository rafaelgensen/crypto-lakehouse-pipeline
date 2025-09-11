# Define the IAM role that Step Functions will assume
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

# Attach necessary permissions (Glue, S3, Logs, etc.)
resource "aws_iam_role_policy_attachment" "step_functions_glue_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "step_functions_basic_execution" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

# Define the Step Function state machine
resource "aws_sfn_state_machine" "glue_etl_pipeline" {
  name     = "coingecko-etl-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "ETL Pipeline: Glue Ingest -> Bronze -> Silver -> Gold",
    StartAt = "GlueJobBIngest",
    States = {
      GlueJobBIngest = {
        Type       = "Task",
        Resource   = "arn:aws:states:::glue:startJobRun.sync",  # .sync waits for job to finish
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
        Next       = "GlueJobSilver",
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
        Next       = "GlueToGold",
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "FailState"
        }]
      },
    GlueToGold = {
        Type       = "Task",  
        # "Task" defines a step that interacts with an AWS service (in this case, AWS Glue)

        Resource   = "arn:aws:states:::glue:startJobRun.sync",
        # This is a Step Functions service integration for AWS Glue
        # ".sync" ensures that the state waits for the Glue job to finish before moving forward

        Parameters = {
          JobName = "coingecko-gold-etl"
          # Replace this with the actual name of your AWS Glue Job (must already exist)

          # Optional: you can pass custom arguments to the job
          # Arguments = {
          #   "--input_bucket" = "s3://mybucket/gold/"
          #   "--target_table" = "analytics_table"
          # }
        },

        End = true,
        # Marks this as the final state in the state machine execution

        Catch = [{
          ErrorEquals = ["States.ALL"],
          # Catches all types of errors — can be more specific (e.g., Glue.JobFailedException)

          ResultPath  = "$.error",
          # Stores error output in this path within the state context

          Next        = "FailState"
          # Specifies which state to transition to if an error is caught
        }]
      },
      FailState = {
        Type    = "Fail",
        Cause   = "ETL Job Failed",
        Error   = "JobExecutionError"
      },
      Retry = [{
			  ErrorEquals     = ["Glue.JobFailedException"],
			  IntervalSeconds = 60,        # Wait time between retries
			  MaxAttempts     = 3,         # Maximum number of attempts
			  BackoffRate     = 2.0        # Wait time increases exponentially
			  }]
    }
  })

  type = "STANDARD" # Also supports EXPRESS, but STANDARD is better for longer Glue jobs
}