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