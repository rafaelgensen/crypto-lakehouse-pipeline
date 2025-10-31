# Bucket para armazenar scripts do Glue
# resource "aws_s3_bucket" "glue-scripts" {
#  bucket = "coingecko-glue-scripts-663354324751"
#}


# Access policy
resource "aws_s3_bucket_policy" "glue-scripts" {
  bucket = "coingecko-glue-scripts-663354324751"
  policy = file("${path.module}/policies/policy_scripts_bucket.json")
}


# Bucket Coin-Gecko - Staging

#resource "aws_s3_bucket" "coingecko-staging" {
#  bucket = "coingecko-staging-663354324751"
#}

# Bucket Coin-Gecko - Staging Policy

resource "aws_s3_bucket_policy" "coingecko-staging" {
  bucket = "coingecko-staging-663354324751"
  policy = file("${path.module}/policies/coingecko-staging-policy.json")
}

# Bucket Coin-Gecko - Bronze

#resource "aws_s3_bucket" "coingecko-bronze" {
#  bucket = "coingecko-bronze-663354324751"
#}

# Bucket Coin-Gecko - bronze Policy

resource "aws_s3_bucket_policy" "coingecko-bronze" {
  bucket = "coingecko-bronze-663354324751"
  policy = file("${path.module}/policies/coingecko-bronze-policy.json")
}

# Bucket Coin-Gecko - Silver

#resource "aws_s3_bucket" "coingecko-silver" {
#  bucket = "coingecko-silver-663354324751"
#}

# Bucket Coin-Gecko - Silver Policy

resource "aws_s3_bucket_policy" "coingecko-silver" {
  bucket = "coingecko-silver-663354324751"
  policy = file("${path.module}/policies/coingecko-silver-policy.json")
}

# Bucket Coin-Gecko - Gold

#resource "aws_s3_bucket" "coingecko-gold" {
#  bucket = "coingecko-gold-663354324751"
#}

# Bucket Coin-Gecko - Gold Policy

resource "aws_s3_bucket_policy" "coingecko-gold" {
  bucket = "coingecko-gold-663354324751"
  policy = file("${path.module}/policies/coingecko-gold-policy.json")
}

# Bucket de logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "logs-coingecko-staging-663354324751"
}

# Habilitar logging
resource "aws_s3_bucket_logging" "staging_logging" {
  bucket = "coingecko-staging-663354324751"
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "staging/"
}

resource "aws_s3_bucket_logging" "bronze_logging" {
  bucket = "coingecko-bronze-663354324751"
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "bronze/"
}

resource "aws_s3_bucket_logging" "silver_logging" {
  bucket = "coingecko-silver-663354324751"
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "silver/"
}

resource "aws_s3_bucket_logging" "gold_logging" {
  bucket = "coingecko-gold-663354324751"
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "gold/"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = file("${path.module}/policies/log-bucket-policy.json")
}