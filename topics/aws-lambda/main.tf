provider "aws" {
  region = "eu-central-1"
}

resource "aws_lambda_function" "rust-iot-thing-lambda" {
  filename         = "topics/${var.topic}/target/lambda/${var.topic}_lambda/bootstrap.zip"
  function_name    = "rust-iot-thing-${var.topic}-lambda"
  role             = aws_iam_role.rust-iot-thing-role.arn
  handler          = "index.test"
  runtime          = "provided.al2"
  source_code_hash = filebase64sha256("topics/${var.topic}/target/lambda/${var.topic}_lambda/bootstrap.zip")
}


resource "aws_iam_role" "rust-iot-thing-role" {
  name = "rust-iot-thing-${var.topic}-role"

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

resource "aws_iam_policy" "rust-iot-thing-policy" {
  name = "rust-iot-thing-${var.topic}-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
               "sns:Publish",
                "iot:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-role" {
  role       = aws_iam_role.rust-iot-thing-role.name
  policy_arn = aws_iam_policy.rust-iot-thing-policy.arn
}

resource "aws_iot_topic_rule" "rust-iot-thing-rule" {
  name        = "rust_iot_thing_${var.topic}_rule"
  enabled     = true
  sql         = "SELECT * FROM '${var.topic}'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.rust-iot-thing-lambda.arn
  }
}

resource "aws_lambda_permission" "rust-iot-thing-permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rust-iot-thing-lambda.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.rust-iot-thing-rule.arn
}

# resource "aws_cloudwatch_log_group" "function_log_group" {
#   name              = "/aws/lambda/${aws_lambda_function.rust-iot-thing-lambda.function_name}"
#   retention_in_days = 7
#   lifecycle {
#     prevent_destroy = false
#   }
# }

# resource "aws_iam_policy" "function_logging_policy" {
#   name = "rust-iot-thing-${var.topic}-logging-policy"
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         Action : [
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Effect : "Allow",
#         Resource : "arn:aws:logs:*:*:*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
#   role       = aws_iam_role.rust-iot-thing-role.id
#   policy_arn = aws_iam_policy.function_logging_policy.arn
# }

resource "aws_iam_policy" "rust-iot-thing-dynamodb-policy" {
  name        = "rust-iot-thing-${var.topic}-dynamodb-policy"
  path        = "/"
  description = "Acces DynamDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "VisualEditor0"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rust-iot-thing-dynamodb-policy-attachment" {
  role       = aws_iam_role.rust-iot-thing-role.id
  policy_arn = aws_iam_policy.rust-iot-thing-dynamodb-policy.arn
}