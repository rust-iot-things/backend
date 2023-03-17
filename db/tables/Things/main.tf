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
