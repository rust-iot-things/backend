module "db" {
  source      = "./db"
  environment = var.environment
}

module "registry-lambda" {
  source      = "./topics/registry/terraform"
  environment = var.environment
  topic       = "registry"
  name        = "registry"
  path        = "topics/registry/target/lambda/registry_lambda"
}

module "thing-input-lambda" {
  source      = "./topics/thing_input/terraform"
  environment = var.environment
  topic       = "thing_input"
  name        = "thing_input"
  path        = "topics/thing_input/target/lambda/thing_input_lambda"
}

