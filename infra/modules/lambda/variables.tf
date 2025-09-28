variable "redshift_workgroup" {
  type        = string
  description = "Nome do workgroup Redshift Serverless"
  default = "lakehouse-wg"
}

variable "redshift_database" {
  type        = string
  description = "Nome do banco de dados Redshift"
  default     = "dev"
}