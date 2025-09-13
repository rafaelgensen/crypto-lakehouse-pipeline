resource "aws_iam_role" "glue_ingest_role" {
  name = "glue-ingest-role"

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

resource "aws_iam_role_policy" "glue_ingest_s3" {
  name = "glue_ingest_s3"
  role = aws_iam_role.glue_ingest_role.id

  policy = file("${path.module}/policy_glue_ingest.json")
}

resource "aws_iam_role_policy_attachment" "glue_ingest" {
  role       = aws_iam_role.glue_ingest_role.name
  policy_arn = aws_iam_policy.glue_ingest_s3.arn
}