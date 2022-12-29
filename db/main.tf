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

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_dynamodb"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "rust-iot-thing-dynamodb-policy" {
  name        = "rust-iot-thing-dynamodb-policy"
  path        = "/"
  description = "Acces DynamDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
        ]
        Effect   = "Allow"
        Resource = "*" # replace with "aws_dynamodb_table.table.arn" as output
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rust-iot-thing-dynamodb-policy-attachment" {
  role       = aws_iam_role.iam_for_lambda.id
  policy_arn = aws_iam_policy.rust-iot-thing-dynamodb-policy.arn
}

module "rust-iot-thing-registry-lambda" {
  source      = "./tables/Things"
  environment = var.environment
  name        = "thing"
  table_name  = "Things"
  lambda_arn  = aws_iam_role.iam_for_lambda.arn
}

module "rust-iot-thing-temperatures-lambda" {
  source      = "./tables/Temperatures"
  environment = var.environment
  name        = "temperatures"
  table_name  = "Temperatures"
  lambda_arn  = aws_iam_role.iam_for_lambda.arn
}

module "rust-iot-thing-humidities-lambda" {
  source      = "./tables/Humidities"
  environment = var.environment
  name        = "humidities"
  table_name  = "Humidities"
  lambda_arn  = aws_iam_role.iam_for_lambda.arn
}