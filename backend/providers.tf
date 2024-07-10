terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.57.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "REDACTED"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud_resume_backend_terraform_state_lock"
  }
}
