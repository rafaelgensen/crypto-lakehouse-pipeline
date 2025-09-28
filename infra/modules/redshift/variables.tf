variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to connect to Redshift (e.g. your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}