resource "aws_redshiftserverless_namespace" "this" {
  namespace_name = "lakehouse-ns"
  admin_username = "lakehouse_admin"
}

resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name       = "lakehouse-wg"
  namespace_name       = aws_redshiftserverless_namespace.this.namespace_name
  iam_roles            = [aws_iam_role.redshift_role.arn]
  publicly_accessible  = true
  security_group_ids   = [aws_security_group.redshift_sg.id]
  subnet_ids           = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}