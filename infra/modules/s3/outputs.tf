output "silver_data_bucket_name" {
  value = aws_s3_bucket.coingecko-storage.bucket
}

output "gold_data_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
}