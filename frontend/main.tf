data "terraform_remote_state" "cloud_resume_backend_tfstate" {
  backend = "s3"

  config = {
    bucket = "REDACTED"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_s3_object" "index" {
  bucket       = data.terraform_remote_state.cloud_resume_backend_tfstate.outputs.s3_domain_bucket_name
  key          = "index.html"
  source       = var.index_path
  content_type = "text/html"
  etag         = filemd5("${var.index_path}")
}

resource "aws_s3_object" "error" {
  bucket       = data.terraform_remote_state.cloud_resume_backend_tfstate.outputs.s3_domain_bucket_name
  key          = "error.html"
  content_type = "text/html"
  source       = var.error_path
  etag         = filemd5("${var.error_path}")
}

resource "aws_s3_object" "scripts_js" {
  bucket       = data.terraform_remote_state.cloud_resume_backend_tfstate.outputs.s3_domain_bucket_name
  key          = "js/scripts.js"
  source       = var.scripts_js_path
  content_type = "application/x-javascript"
  etag         = filemd5("${var.scripts_js_path}")
}

resource "aws_s3_object" "profile_jpg" {
  bucket       = data.terraform_remote_state.cloud_resume_backend_tfstate.outputs.s3_domain_bucket_name
  key          = "img/profile.jpg"
  source       = var.profile_jpg_path
  content_type = "image/jpeg"
  etag         = filemd5("${var.profile_jpg_path}")
}

resource "aws_s3_object" "styles_css" {
  bucket       = data.terraform_remote_state.cloud_resume_backend_tfstate.outputs.s3_domain_bucket_name
  key          = "css/styles.css"
  source       = var.styles_css_path
  content_type = "text/css"
  etag         = filemd5("${var.styles_css_path}")
}