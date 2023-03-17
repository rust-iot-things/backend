resource "aws_lambda_function" "lambda" {
  filename         = "db/api-gateway/index.zip"
  function_name    = "rust-iot-thing-crud"
  role             = var.lambda_arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("db/api-gateway/index.zip")

  runtime = "nodejs16.x"
}

resource "aws_lambda_permission" "apigw_lambda_things" {
  statement_id  = "APIGatewayThings"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/things"
}

resource "aws_lambda_permission" "apigw_lambda_things_id" {
  statement_id  = "APIGatewayThingsID"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/things/{id}"
}

resource "aws_lambda_permission" "apigw_lambda_things_id_db" {
  statement_id  = "APIGatewayThingsIDDB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/things/{id}/{db}"
}

resource "aws_lambda_permission" "apigw_lambda_things_id_lamp" {
  statement_id  = "APIGatewayThingsIDLamp"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/things/{id}/{lamp}"
}

resource "aws_lambda_permission" "apigw_lambda_things_id_rgb" {
  statement_id  = "APIGatewayThingsIDRGB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/things/{id}/{rgb}"
}

resource "aws_apigatewayv2_api" "api" {
  name          = "rust-iot-thing-crud"
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

resource "aws_apigatewayv2_route" "route-get-things-id" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /things/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_route" "route-put-things-id" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /things/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_route" "route-get-things" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /things"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_route" "route-put-things" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /things"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_route" "route-get-things-id-db" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /things/{id}/{db}"
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
