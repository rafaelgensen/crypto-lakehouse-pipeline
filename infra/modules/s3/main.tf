

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
  policy = file("${path.root}/policies/coingecko-storage-policy.json")
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
  policy = file("${path.root}/policies/log-bucket-policy.json")
}