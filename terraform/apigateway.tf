# --- API Gateway (HTTP API) ---
resource "aws_apigatewayv2_api" "http_api" {
  name          = "llm_scores_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
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