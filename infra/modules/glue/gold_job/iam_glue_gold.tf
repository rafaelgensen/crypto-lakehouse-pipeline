resource "aws_iam_role" "glue_gold_role" {
  name = "glue-gold-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "glue.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_gold_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_gold_access" {
  name = "glue-gold-s3-access"
  role = aws_iam_role.glue_gold_role.id

  policy = file("${path.module}/policy_glue_gold.json")
}