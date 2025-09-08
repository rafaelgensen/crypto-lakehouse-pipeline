

# Bucket Backend - States
resource "aws_s3_bucket" "coingecko-states" {
  bucket = "coingecko-states-663354324751"
}


# Bucket Coin-Gecko - Staging

resource "aws_s3_bucket" "coingecko-staging" {
  bucket = "coingecko-staging-663354324751"
}

# Bucket Coin-Gecko - Staging Policy

resource "aws_s3_bucket_policy" "coingecko-staging" {
  bucket = aws_s3_bucket.coingecko-staging.id
  policy = file("${path.module}/policies/coingecko-staging-policy.json")
}

# Bucket Coin-Gecko - Bronze

resource "aws_s3_bucket" "coingecko-bronze" {
  bucket = "coingecko-bronze-663354324751"
}

# Bucket Coin-Gecko - bronze Policy

resource "aws_s3_bucket_policy" "coingecko-bronze" {
  bucket = aws_s3_bucket.coingecko-bronze.id
  policy = file("${path.module}/policies/coingecko-bronze-policy.json")
}

# Bucket Coin-Gecko - Silver

resource "aws_s3_bucket" "coingecko-silver" {
  bucket = "coingecko-silver-663354324751"
}

# Bucket Coin-Gecko - Silver Policy

resource "aws_s3_bucket_policy" "coingecko-silver" {
  bucket = aws_s3_bucket.coingecko-silver.id
  policy = file("${path.module}/policies/coingecko-silver-policy.json")
}

# Bucket Coin-Gecko - Gold

resource "aws_s3_bucket" "coingecko-gold" {
  bucket = "coingecko-gold-663354324751"
}

# Bucket Coin-Gecko - Gold Policy

resource "aws_s3_bucket_policy" "coingecko-gold" {
  bucket = aws_s3_bucket.coingecko-gold.id
  policy = file("${path.module}/policies/coingecko-gold-policy.json")
}

# Bucket de logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "logs-coingecko-staging-663354324751"
}

# Habilitar logging
resource "aws_s3_bucket_logging" "data_logging" {
  bucket = aws_s3_bucket.coingecko-staging.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = file("${path.module}/policies/log-bucket-policy.json")
}