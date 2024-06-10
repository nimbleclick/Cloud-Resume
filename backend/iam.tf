# Github OIDC Provider, Role, and Permissions

data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    sid    = "AssumeGitHubProviderRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["${aws_iam_openid_connect_provider.github.arn}"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:nimbleclick/Cloud-Resume:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "assume_role_github" {
  name               = "assume_role_github"
  description        = "Allow Github to assume role and process actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role_policy.json

  tags = merge(var.tags)
}

data "aws_iam_policy_document" "github_update_resources" {
  statement {
    sid    = "UpdateResourcesWithGithubActions"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectACL",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:ListBucketObjects",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.domain.arn}",
      "${aws_s3_bucket.domain.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "github_update_resources_policy" {
  name   = "update_resources_github_actions"
  policy = data.aws_iam_policy_document.github_update_resources.json
}

resource "aws_iam_role_policy_attachment" "update_resources_attach" {
  role       = aws_iam_role.assume_role_github.name
  policy_arn = aws_iam_policy.github_update_resources_policy.arn
}

data "aws_iam_policy_document" "tfstate_bucket_permissions" {
  statement {
    sid    = "UpdateFrontendTFStateFile"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "${var.frontend_state_bucket_arn}",
      "${var.frontend_state_bucket_arn}/prod/*"
    ]
  }

  statement {
    sid    = "ReadBackendTFStateFile"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "${var.backend_state_bucket_arn}",
      "${var.backend_state_bucket_arn}/prod/*"
    ]
  }

}

resource "aws_iam_policy" "tfstate_bucket_access" {
  name   = "tf_state_access"
  policy = data.aws_iam_policy_document.tfstate_bucket_permissions.json
}

resource "aws_iam_role_policy_attachment" "tf_state_bucket_access_attach" {
  role       = aws_iam_role.assume_role_github.name
  policy_arn = aws_iam_policy.tfstate_bucket_access.arn

}

data "aws_iam_policy_document" "frontend_dynamodb_state_lock_permissions" {
  statement {
    sid    = "AccessDynamoDBStateLockTable"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "${aws_dynamodb_table.cloud_resume_frontend_terraform_state_lock.arn}",
      "${aws_dynamodb_table.cloud_resume_frontend_terraform_state_lock.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "frontend_dynamodb_state_lock_access" {
  name   = "tf_state_lock_frontend_access"
  policy = data.aws_iam_policy_document.frontend_dynamodb_state_lock_permissions.json
}

resource "aws_iam_role_policy_attachment" "frontend_dynamodb_state_lock_access_attach" {
  role       = aws_iam_role.assume_role_github.name
  policy_arn = aws_iam_policy.frontend_dynamodb_state_lock_access.arn

}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = merge(var.tags)
}

# Lambda Visitor Counter Role and Permissions

data "aws_iam_policy_document" "lambda_view_count_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_view_count_permissions" {
  statement {
    sid    = "AllowDynamodbItemModification"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
      "dynamodb:UpdateItem"
    ]

    resources = [
      "${aws_dynamodb_table.cloud_resume_view_count_table.arn}/*",
      "${aws_dynamodb_table.cloud_resume_view_count_table.arn}"
    ]
  }
  statement {
    sid    = "AllowCoudwatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    sid    = "AllowS3BucketAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.lambda_source_code_bucket.arn,
      "${aws_s3_bucket.lambda_source_code_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_view_count_policy" {
  name   = "lambda_view_count_policy"
  policy = data.aws_iam_policy_document.lambda_view_count_permissions.json
}

resource "aws_iam_role" "lambda_view_count_execution_role" {
  name               = "lambda_view_count_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_view_count_assume_role.json

  tags = merge(var.tags)
}

resource "aws_iam_role_policy_attachment" "lambda_view_count_policy_attachment" {
  role       = aws_iam_role.lambda_view_count_execution_role.name
  policy_arn = aws_iam_policy.lambda_view_count_policy.arn
}

# Lambda Cloudfront Invalidation Role and Permissions

data "aws_iam_policy_document" "lambda_cloudfront_invalidation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_cloudfront_invalidation_permissions" {
  statement {
    sid    = "AllowCloudfrontInvalidation"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      "${aws_cloudfront_distribution.cloud_resume_distribution.arn}"
    ]
  }
}

resource "aws_iam_policy" "lambda_cloudfront_invalidation_policy" {
  name   = "lambda_cloudfront_invalidation_policy"
  policy = data.aws_iam_policy_document.lambda_cloudfront_invalidation_permissions.json
}

resource "aws_iam_role" "lambda_cloudfront_invalidation_role" {
  name               = "lambda_cloudfront_invalidation_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_cloudfront_invalidation_assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_cloudfront_invalidation_policy" {
  role       = aws_iam_role.lambda_cloudfront_invalidation_role.name
  policy_arn = aws_iam_policy.lambda_cloudfront_invalidation_policy.arn
}