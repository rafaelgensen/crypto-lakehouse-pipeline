

# Bucket Backend - Standard
resource "aws_s3_bucket" "coingecko-states" {
  bucket = "coingecko-states-663354324751"
}



# Bucket Coin-Gecko - Standard
resource "aws_s3_bucket" "coingecko-storage" {
  bucket = "coingecko-storage-663354324751"
}

# Bucket Coin-Gecko Policy

resource "aws_s3_bucket_policy" "coingecko-storage" {
  bucket = aws_s3_bucket.coingecko-storage.id
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGlueJobsAndLambdaAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::663354324751:role/glue-bronze-role",
          "arn:aws:iam::663354324751:role/glue-silver-role",
          "arn:aws:iam::663354324751:role/lambda-ingestion-role"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::coingecko-storage-663354324751",
        "arn:aws:s3:::coingecko-storage-663354324751/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "663354324751"
        }
      }
    }
  ]
})
}

# Bucket de logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "logs-coingecko-storage-663354324751"
}

# Habilitar logging
resource "aws_s3_bucket_logging" "data_logging" {
  bucket = aws_s3_bucket.coingecko-storage.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ServerAccessLogsPolicy",
      "Effect": "Allow",
      "Principal": {
        "Service": "logging.s3.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::logs-coingecko-storage-663354324751/logs/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "663354324751"
        }
      }
    }
  ]
})
}