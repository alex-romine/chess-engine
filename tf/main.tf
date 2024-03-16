locals {
  base_name = "chess-engine"
  deploy_time = timestamp()
}

############################################
# Set up Infra
############################################
resource "terraform_data" "package_app" {
  provisioner "local-exec" {
    # For some reason the make directive doesn't do the rm -rf ./package on deploy, so it's here too
    command = "cd ..; rm -rf ./package; make package"
  }

  triggers_replace = {
    timestamp = local.deploy_time
  }
}

data "archive_file" "lambda" {
  depends_on = [terraform_data.package_app]

  type        = "zip"
  source_dir  = "../package"
  output_path = "lambda_function_payload-${local.deploy_time}.zip"
}

############################################
# IAM
############################################
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.base_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}

############################################
# Lambda
############################################
resource "aws_lambda_function" "lambda" {
  filename      = data.archive_file.lambda.output_path
  function_name = "${local.base_name}-lambda-function"
  role          = aws_iam_role.lambda.arn
  handler       = "app.main.handler"
  timeout       = 600

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime       = "python3.11"
  architectures = ["arm64"]

  environment {
    variables = {
      SF_VERSION = "sf_16.1"
      SF_ARCH    = "macos-m1-apple-silicon"
    }
  }
}