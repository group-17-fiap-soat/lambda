# Lambda Role

data "aws_iam_role" "role" {
  name = "RootRole"
}

# Lambda Function
resource "aws_lambda_function" "check_user" {
  filename         = "check_user.zip"
  function_name    = "check-user-email"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  role             = data.aws_iam_role.role.arn
  timeout          = 10
  memory_size      = 128
  source_code_hash = filebase64sha256("check_user.zip")

  environment {
    variables = {
      DB_HOST     = var.db_host
      DB_NAME     = var.db_name
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
      DB_PORT     = var.db_port
    }
  }

}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.auth.execution_arn}/*/*"
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "auth" {
  name          = "auth-api"
  protocol_type = "HTTP"
}

# Integração com Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.auth.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.check_user.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Rota: POST /auth
resource "aws_apigatewayv2_route" "auth_route" {
  api_id    = aws_apigatewayv2_api.auth.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deploy automático
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.auth.id
  name        = "$default"
  auto_deploy = true
}
