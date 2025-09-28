resource "aws_redshiftserverless_namespace" "this" {
  namespace_name = "lakehouse-ns"
}

resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name       = "lakehouse-wg"
  namespace_name       = aws_redshiftserverless_namespace.this.namespace_name
  publicly_accessible  = true
  security_group_ids   = [aws_security_group.redshift_sg.id]
  subnet_ids           = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "null_resource" "associate_iam_role" {
  provisioner "local-exec" {
    command = <<EOT
      aws redshift-serverless update-namespace \
        --namespace-name ${aws_redshiftserverless_namespace.this.namespace_name} \
        --iam-roles ${aws_iam_role.redshift_role.arn}
    EOT
  }

  depends_on = [
    aws_redshiftserverless_namespace.this,
    aws_iam_role.redshift_role
  ]

  triggers = {
    always_run = timestamp()
  }
}