resource "aws_iam_role" "glue_silver_role" {
  name = "glue-silver-role"

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
  role       = aws_iam_role.glue_silver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_silver_access" {
  name = "glue-silver-s3-access"
  role = aws_iam_role.glue_silver_role.id

  policy = file("${path.module}/policy_glue_silver.json")
}