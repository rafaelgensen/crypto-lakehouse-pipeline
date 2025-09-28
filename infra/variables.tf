variable "API_KEY_CG" {
  description = "API key for external service"
  type        = string
  sensitive   = true
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to acessar Redshift"
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}