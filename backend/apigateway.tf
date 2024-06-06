resource "aws_apigatewayv2_api" "track_view_count" {
  name          = "track_view_count_api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.increment_view_count.arn

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }

  tags = merge(var.tags)
}
#
resource "aws_apigatewayv2_stage" "prod" {
  api_id = aws_apigatewayv2_api.track_view_count.id

  name        = "Prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.view_count_http_api.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourePath             = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}
resource "aws_apigatewayv2_integration" "view_count_integration" {
  api_id = aws_apigatewayv2_api.track_view_count.id

  integration_uri        = aws_lambda_function.increment_view_count.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_view_count" {
  api_id    = aws_apigatewayv2_api.track_view_count.id
  route_key = "ANY /${aws_lambda_function.increment_view_count.function_name}"
  target    = "integrations/${aws_apigatewayv2_integration.view_count_integration.id}"
}