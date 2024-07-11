
# Frontend S3 Buckets and Configurations

resource "aws_s3_bucket" "domain" {
  bucket = var.domain_name

  tags = merge(var.tags)
}

resource "aws_s3_bucket_public_access_block" "domain_bucket_access_block" {
  bucket = aws_s3_bucket.domain.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "domain_bucket_policy" {
  bucket = aws_s3_bucket.domain.id
  policy = data.aws_iam_policy_document.domain_bucket_permissions.json
}

data "aws_iam_policy_document" "domain_bucket_permissions" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.domain.arn}/*"] 

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cloud_resume_distribution.id}"]
    }
  }
}

resource "aws_s3_bucket" "subdomain" {
  bucket = var.subdomain_name

  tags = merge(var.tags)
}

resource "aws_s3_bucket_acl" "subdomain_bucket_acl" {
  bucket = aws_s3_bucket.subdomain.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "subdomain_config" {
  bucket = aws_s3_bucket.subdomain.id

  redirect_all_requests_to {
    host_name = var.domain_name
  }
}

# Lambda Source Code Bucket, Objets, and Permissions

resource "aws_s3_bucket" "lambda_source_code_bucket" {
  bucket = var.lambda_source_code_bucket_name

  tags = merge(var.tags)
}

resource "aws_s3_object" "lambda_view_count_source_code" {
  bucket       = aws_s3_bucket.lambda_source_code_bucket.id
  key          = "increment_view_count.zip"
  content_type = "application/zip"
  source       = var.lambda_view_count_path
  acl          = "private"
  etag         = filemd5(data.archive_file.increment_view_count_script.output_path)
}

resource "aws_s3_object" "lambda_cloudfront_invalidation_code" {
  bucket       = aws_s3_bucket.lambda_source_code_bucket.id
  key          = "cloudfront_invalidation.zip"
  content_type = "application/zip"
  source       = var.lambda_cloudfront_invalidation_path
  acl          = "private"
  etag         = filemd5(data.archive_file.cloudfront_invalidation_script.output_path)
}

resource "aws_s3_bucket_ownership_controls" "lambda_source_code_ownership_controls" {
  bucket = aws_s3_bucket.lambda_source_code_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_source_code_bucket_acl" {
  bucket = aws_s3_bucket.lambda_source_code_bucket.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket.lambda_source_code_bucket,
    aws_s3_bucket_ownership_controls.lambda_source_code_ownership_controls
  ]
}

resource "aws_s3_bucket_public_access_block" "lambda_source_code_bucket_block" {
  bucket = aws_s3_bucket.lambda_source_code_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_source_code_bucket_encryption" {
  bucket = aws_s3_bucket.lambda_source_code_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "lambda_source_code_bucket_policy" {
  bucket = aws_s3_bucket.lambda_source_code_bucket.id
  policy = data.aws_iam_policy_document.lambda_source_code_bucket_permissions.json
}

data "aws_iam_policy_document" "lambda_source_code_bucket_permissions" {
  statement {
    sid    = "LambdaFunctionBucketAcess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.lambda_view_count_execution_role.arn}"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.lambda_source_code_bucket.arn}/*"]
  }
}

# Cloudtrail Bucket and Permissions

resource "aws_s3_bucket" "cloud_resume_cloudtrail_logs" {
  bucket = var.cloudtrail_bucket_name
  tags   = merge(var.tags)
}

resource "aws_s3_bucket_ownership_controls" "cloud_resume_cloudtrail_bucket_ownership_controls" {
  bucket = aws_s3_bucket.cloud_resume_cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloud_resume_cloudtrail_bucket_acl" {
  bucket = aws_s3_bucket.cloud_resume_cloudtrail_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket.cloud_resume_cloudtrail_logs,
    aws_s3_bucket_ownership_controls.cloud_resume_cloudtrail_bucket_ownership_controls
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloud_resume_cloudtrail_log_encryption" {
  bucket = aws_s3_bucket.cloud_resume_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloud_resume_cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloud_resume_cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloud_resume_cloudtrail_permissions.json
}

data "aws_iam_policy_document" "cloud_resume_cloudtrail_permissions" {
  statement {
    sid    = "CloudtrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = ["${aws_s3_bucket.cloud_resume_cloudtrail_logs.arn}"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloud_resume_cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}"]
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Terraform Frontend Remote State Bucket

resource "aws_s3_bucket" "terraform_frontend_cloud_resume" {
  bucket = var.frontend_state_bucket
  tags   = merge(var.tags)
}

resource "aws_s3_bucket_ownership_controls" "cloud_resume_frontend_state_bucket_ownership_controls" {
  bucket = aws_s3_bucket.terraform_frontend_cloud_resume.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloud_resume_frontend_state_bucket_acl" {
  bucket = aws_s3_bucket.terraform_frontend_cloud_resume.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket.terraform_frontend_cloud_resume,
    aws_s3_bucket_ownership_controls.cloud_resume_frontend_state_bucket_ownership_controls
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloud_resume_frontend_state_bucket_encryption" {
  bucket = aws_s3_bucket.terraform_frontend_cloud_resume.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloud_resume_frontend_state_bucket_block" {
  bucket = aws_s3_bucket.terraform_frontend_cloud_resume.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}