module "rust-iot-thing-lamp-lambda" {
  source        = "./../../base"
  environment   = var.environment
  topic         = "thing_input"
  name          = "lamp"
  path          = "db/microservices/lamp/target/lambda/lamp_lambda"
  id            = var.id
  execution_arn = var.execution_arn
}
