variable "aws_region" {
  default = "us-east-1"
}

variable "backend_state_bucket_arn" {
  default = "BACKEND_STATE_BUCKET_ARN"
}

variable "cloudtrail_name" {
  default = "cloud_resume_cloudtrail"
}

variable "cloudtrail_bucket_name" {
  default = "CLOUDTRAIL_BUCKET_NAME"
}

variable "frontend_state_bucket" {
  default = "FRONTEND_STATE_BUCKET_NAME"
}

variable "frontend_state_bucket_arn" {
  default = "FRONTEND_STATE_BUCKET_ARN"
}

variable "hosted_zone_id" {
  default = "HOSTED_ZONE_ID"
}

variable "lambda_source_code_bucket_name" {
  default = "LAMBDA_SOURCE_CODE_BUCKET_NAME"
}

variable "lambda_cloudfront_invalidation_path" {
  default = "functions/cloudfront_invalidation/cloudfront_invalidation.zip"
}

variable "lambda_view_count_path" {
  default = "functions/increment_view_count/increment_view_count.zip"
}

variable "domain_name" {
  default = "hirethisswellguy.com"
}

variable "subdomain_name" {
  default = "www.hirethisswellguy.com"
}

variable "tags" {
  description = "mutual tags shared amongst all resources in the repo"
  type        = map(any)
  default = {
    Env         = "PROD"
    IaC         = "Terraform"
    Application = "Cloud Resume"
    Github_Repo = "nimbleclick/Cloud-Resume"
  }
}