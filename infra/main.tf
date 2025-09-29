# infra/main.tf

provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "coingecko-states-663354324751"
    key     = "data-pipeline/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
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

resource "aws_ssm_parameter" "api_key" {
  name  = "/coing-gecko/api_key"
  type  = "SecureString"
  value = var.API_KEY_CG
}

module "glue" {
  source = "./modules/glue"

  depends_on = [module.s3]
}

module "glue_ingest" {
  source = "./modules/glue/ingest_job"

  depends_on = [
    module.s3,
    aws_ssm_parameter.api_key
  ]
}

module "glue_bronze" {
  source = "./modules/glue/bronze_job"

  depends_on = [module.s3]
}

module "glue_silver" {
  source = "./modules/glue/silver_job"

  depends_on = [module.s3]
}

module "glue_gold" {
  source = "./modules/glue/gold_job"

  depends_on = [module.s3]
}

module "stepfunc" {
  source = "./modules/stepfunc"
  lambda_function_arn = module.lambda.bootstrap_lambda_arn
  depends_on = [
    module.glue_bronze, 
    module.glue_gold, 
    module.glue_silver, 
    module.glue_ingest, 
    module.glue, 
    module.lambda 
    ]
}

module "lambda" {
  source = "./modules/lambda"
}

module "redshift" {
  source = "./modules/redshift"
}