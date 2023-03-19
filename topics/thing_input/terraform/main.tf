module "rust-iot-thing-registry-lambda" {
  source      = "./../../aws-lambda"
  environment = var.environment
  topic       = var.topic
  name        = var.name
  path        = var.path
}
