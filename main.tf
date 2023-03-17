module "db" {
  source      = "./db"
  environment = var.environment
}

module "registry-lambda" {
  source      = "./topics/registry/terraform"
  environment = var.environment
  topic       = "registry"
}

module "thing-input-lambda" {
  source      = "./topics/thing_input/terraform"
  environment = var.environment
  topic       = "thing_input"
}
