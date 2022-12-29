module "db" {
  source      = "./db"
  environment = var.environment
}

module "registry-lambda" {
  source = "./topics/registry/terraform"
  environment = var.environment
  topic = "registry"
}
