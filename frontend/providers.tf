terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.4.0"
    }

    local = {
      source = "hashicorp/local"
    }
  }
  required_version = "1.4.6"
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "REDACTED"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud_resume_frontend_terraform_state_lock"
    encrypt        = true
  }
}