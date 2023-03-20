module "rust-iot-thing-rgb-lambda" {
  source        = "./../../base"
  environment   = var.environment
  topic         = "thing_input"
  name          = "rgb"
  path          = "db/microservices/rgb/target/lambda/rgb_lambda"
  id            = var.id
  execution_arn = var.execution_arn
}
