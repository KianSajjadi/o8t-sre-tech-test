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
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      latency        = "$context.responseLatency"
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

# Filter logs for 5xx
resource "aws_cloudwatch_log_metric_filter" "api_5xx_errors" {
  name           = "HTTP-API-5xx-Errors"
  pattern        = "{ $.status = 5* }"
  log_group_name = aws_cloudwatch_log_group.api_logs.name

  metric_transformation {
    name          = "5xxErrorCount"
    namespace     = "ApiCustomMetrics"
    value         = "1"
    default_value = "0"
  }
}

# API gateway latency
resource "aws_cloudwatch_log_metric_filter" "api_latency" {
  name           = "HTTP-API-Latency"
  pattern        = "{ $.latency = * }"
  log_group_name = aws_cloudwatch_log_group.api_logs.name

  metric_transformation {
    name      = "ResponseLatency"
    namespace = "ApiCustomMetrics"
    value     = "$.latency"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_high" {
  alarm_name          = "api-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5xxErrorCount"
  namespace           = "ApiCustomMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This alarm monitors API 5xx errors exceeding 5 in 5 minutes"

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "api_high_latency" {
  alarm_name          = "api-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ResponseLatency"
  namespace           = "ApiCustomMetrics"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"
  alarm_description   = "This alarm monitors API latency exceeding 5 seconds"

  alarm_actions = [aws_sns_topic.alerts.arn]
}