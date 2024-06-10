resource "aws_cloudwatch_log_group" "lambda_view_counter" {
  name              = "/aws/lambda/${aws_lambda_function.increment_view_count.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "view_count_http_api" {
  name = "/aws/api-gw/${aws_apigatewayv2_api.track_view_count.name}"

  retention_in_days = 14

  tags = merge(var.tags)
}