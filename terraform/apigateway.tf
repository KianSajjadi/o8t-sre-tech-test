# --- API Gateway (HTTP API) ---
resource "aws_apigatewayv2_api" "http_api" {
  name          = "llm_scores_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.llm_service.invoke_arn
}

resource "aws_apigatewayv2_route" "get_llms" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /llms"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


# Cloudwatch
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/v2/api-gateway/${aws_apigatewayv2_api.http_api.name}"
  retention_in_days = 30
}