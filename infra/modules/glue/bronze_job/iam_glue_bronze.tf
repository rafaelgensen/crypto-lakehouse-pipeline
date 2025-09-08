resource "aws_iam_role" "glue_bronze_role" {
  name = "glue-bronze-role"

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
  role       = aws_iam_role.glue_bronze_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_bronze_access" {
  name = "glue-bronze-s3-access"
  role = aws_iam_role.glue_bronze_role.id

  policy = file("${path.module}/policy_glue_bronze.json")
}