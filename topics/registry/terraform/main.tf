module "rust-iot-thing-registry-lambda" {
  source = "./../aws-terraform/aws-lambda"
  environment = var.environment
  topic = var.topic
}
