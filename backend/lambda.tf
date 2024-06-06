resource "aws_lambda_function" "increment_view_count" {
  function_name    = "increment_view_count"
  s3_bucket        = aws_s3_bucket.lambda_source_code_bucket.id
  s3_key           = aws_s3_object.lambda_view_count_source_code.key
  role             = aws_iam_role.lambda_view_count_execution_role.arn
  handler          = "increment_view_count.lambda_handler"
  source_code_hash = data.archive_file.increment_view_count_script.output_base64sha256
  runtime          = "python3.9"

  tags = merge(var.tags)
}

resource "aws_lambda_permission" "api_gateway_trigger" {

  statement_id  = "AllowAPIGatewayInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.increment_view_count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.track_view_count.execution_arn}/*/*/${aws_lambda_function.increment_view_count.function_name}"
}

data "archive_file" "increment_view_count_script" {
  type        = "zip"
  source_file = "functions/increment_view_count/increment_view_count.py"
  output_path = "functions/increment_view_count/increment_view_count.zip"
}

resource "aws_lambda_function" "cloudfront_invalidation" {
  function_name    = "cloudfront_invalidation"
  handler          = "cloudfront_invalidation.lambda_handler"
  role             = aws_iam_role.lambda_cloudfront_invalidation_role.arn
  runtime          = "python3.9"
  s3_bucket        = aws_s3_bucket.lambda_source_code_bucket.id
  s3_key           = aws_s3_object.lambda_cloudfront_invalidation_code.key
  source_code_hash = data.archive_file.cloudfront_invalidation_script.output_base64sha256
  timeout          = 90

  tags = merge(var.tags)
}

resource "aws_lambda_permission" "s3_lambda_invoke" {
  statement_id  = "AllowS3ToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_invalidation.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.domain.arn
}

resource "aws_s3_bucket_notification" "s3_lambda_trigger" {
  bucket = aws_s3_bucket.domain.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudfront_invalidation.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "index"
    filter_suffix       = ".html"
  }
}

data "archive_file" "cloudfront_invalidation_script" {
  type        = "zip"
  source_file = "functions/cloudfront_invalidation/cloudfront_invalidation.py"
  output_path = "functions/cloudfront_invalidation/cloudfront_invalidation.zip"
}