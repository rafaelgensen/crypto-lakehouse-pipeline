output "bootstrap_lambda_arn" {
  description = "ARN da função Lambda Bootstrap"
  value       = aws_lambda_function.bootstrap.arn
}
