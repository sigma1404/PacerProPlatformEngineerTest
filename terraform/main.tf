terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "target_ec2" {
  ami           = "ami-03ea746da1a2e36e7"
  instance_type = "t2.micro"

  tags = {
    Name = "target-ec2-instance"
  }
}

resource "aws_sns_topic" "target_sns_topic" {
  name = "target-sns-topic"
}

resource "aws_sns_topic_subscription" "target_sns_subscription" {
  topic_arn = aws_sns_topic.target_sns_topic.arn
  protocol  = "email"
  endpoint  = "sudeeptechops@gmail.com"
}

resource "aws_iam_policy" "lambda_sns_policy" {
  name        = "lambda_sns_policy"
  description = "IAM policy for Lambda to restart ec2 and publish to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:startInstances",
          "ec2:stopInstances"
        ]
        Effect   = "Allow"
        Resource = aws_instance.target_ec2.arn
      },
      {
        Action = [
          "sns:Publish",
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.target_sns_topic.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_sns_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

data "archive_file" "lambda_source_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "ec2_sns_lambda" {
  function_name = "ec2_sns_manager"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.lambda_source_zip.output_path
  source_code_hash = data.archive_file.lambda_source_zip.output_base64sha256
  timeout      = 480

  environment {
    variables = {
      EC2_INSTANCE_ID = aws_instance.target_ec2.id
      SNS_ARN   = aws_sns_topic.target_sns_topic.arn
    }
  }
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.ec2_sns_lambda.function_name
  authorization_type = "NONE"
}
