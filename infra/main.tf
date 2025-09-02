# infra/main.tf
provider "aws" {
  region = "us-east-1"
}


terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "coingecko-states-663354324751"
    key            = "data-pipeline/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

# Tags globais
locals {
  common_tags = {
    Project     = "coingecko-pipeline"
    Environment = terraform.workspace
    Owner       = "time-data"
  }
}

module "s3" {
  source = "./modules/s3"
}
