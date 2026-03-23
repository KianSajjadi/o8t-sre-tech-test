# --- Lambda Function ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "llm_service" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "llm_scores_service"
  role             = aws_iam_role.lambda_role.arn
  handler          = "app.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.llm_scores.name
    }
  }

  tracing_config {
    mode = "Active" # Enable X-Ray tracing
  }

  reserved_concurrent_executions = var.lambda_reserved_concurrency
}

resource "aws_lambda_provisioned_concurrency_config" "default" {
  function_name                     = aws_lambda_function.llm_service.function_name
  provisioned_concurrent_executions = var.provisioned_concurrency_executions
  qualifier                         = aws_lambda_function.llm_service.version
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.llm_service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.llm_service.function_name}"
  # 30 days for iso27001 compliance
  retention_in_days = 30
}


# number of errors over 300 seconds greater than 5 triggers an alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name = "llm_service_lambda_errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = "300"
  statistic = "Sum"
  threshold = 5
  alarm_description = "Lambda function ${aws_lambda_function.llm_service.function_name} has more than 5 errors in 5 minutes"
  alarm_actions = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.llm_service.function_name
  }
}

# invocation duration of greater than 5 seconds will trigger
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name = "llm_service_lambda_duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = "300"
  statistic = "Average"
  threshold = "5000"
  alarm_description = "Lambda function ${aws_lambda_function.llm_service.function_name} taking longer than 5 seconds"
  alarm_actions = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.llm_service.function_name
  }
}

# number of lambda invocations that are throttling > 5 over a 5min period
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name = "llm_service_lambda_throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = "300"
  statistic = "Sum"
  threshold = "5"
  alarm_description = "Lambda function ${aws_lambda_function.llm_service.function_name} throttling more than 5 times per 5 min"
  alarm_actions = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.llm_service.function_name
  }
}