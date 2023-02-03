resource "aws_ecs_cluster" "cluster" {
  name = var.environment
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_dynamodb_table" "table" {
  name           = var.table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_function" "lambda" {
  filename         = "db/tables/${var.table_name}/index.zip"
  function_name    = "rust-iot-thing-crud-${var.name}"
  role             = var.lambda_arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("db/tables/${var.table_name}/index.zip")

  runtime = "nodejs16.x"
}

resource "aws_lambda_permission" "apigw_lambda_items" {
  statement_id  = "APIGatewayItems"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/items"
}

resource "aws_lambda_permission" "apigw_lambda_items_id" {
  statement_id  = "APIGatewayItemsID"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/items/{id}"
}

resource "aws_apigatewayv2_api" "api" {
  name          = "rust-iot-thing-crud-${var.name}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = ["*"]
    max_age           = 3600
  }
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  lifecycle {
    ignore_changes = [
      deployment_id,
      default_route_settings
    ]
  }
}

resource "aws_apigatewayv2_route" "route-get-items-id" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_route" "route-put-items-id" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_route" "route-get-items" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_route" "route-put-items" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /items"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"

  payload_format_version = "2.0"

  lifecycle {
    ignore_changes = [
      passthrough_behavior
    ]
  }
}
