locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = "us-east-2"

  base_url    = "chesstransformer.com"
  api_url     = "api.${local.base_url}"
  deploy_time = timestamp()

  base_name            = "chess-engine"
  function_name        = "${local.base_name}-lambda-function"
  lambda_arn           = "arn:aws:lambda:${local.aws_region}:${local.account_id}:function:${local.function_name}"
  apig_integration_arn = "arn:aws:apigateway:${local.aws_region}:lambda:path/2015-03-31/functions/${local.lambda_arn}/invocations"
}

############################################
# Set up Infra
############################################
resource "terraform_data" "package_app" {
  provisioner "local-exec" {
    # For some reason the make directive doesn't do the rm -rf ./package on deploy, so it's here too
    command = "cd ..; rm -rf ./package; rm -rf tf/lambda_function*; make package"
  }

  triggers_replace = {
    main_py = filemd5("../app/main.py")
  }
}

data "archive_file" "lambda" {
  depends_on = [terraform_data.package_app]

  type        = "zip"
  source_dir  = "${path.module}/../package"
  output_path = "${path.module}/lambda_function_payload-${local.deploy_time}.zip"
}

data "aws_s3_bucket" "lambda_code" {
  bucket = "lambda-code-ajromine"
}

resource "aws_s3_object" "lambda_code" {
  bucket = data.aws_s3_bucket.lambda_code.bucket
  key    = "${local.function_name}_payload-${local.deploy_time}.zip"
  source = data.archive_file.lambda.output_path
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
  name               = local.function_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}

############################################
# Lambda
############################################
resource "aws_lambda_function" "lambda" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "app.main.handler"
  timeout       = 600
  
  s3_bucket = aws_s3_object.lambda_code.bucket
  s3_key = aws_s3_object.lambda_code.key

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime       = "python3.11"
  architectures = ["x86_64"]

  environment {
    variables = {
      SF_VERSION = "sf_16.1"
      SF_ARCH    = "amazon-linux-x86-64"
      IS_LAMBDA  = "True"
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda_chat" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${local.aws_region}:${local.account_id}:${data.aws_api_gateway_rest_api.be.id}/*/${aws_api_gateway_method.be_chat.http_method}${aws_api_gateway_resource.be_chat.path}"
}

###############################################
# APIG
###############################################
data "aws_api_gateway_rest_api" "be" {
  name = replace(local.api_url, ".", "-")
}

########### /best_moves POST ################
resource "aws_api_gateway_resource" "be_chat" {
  rest_api_id = data.aws_api_gateway_rest_api.be.id
  parent_id   = data.aws_api_gateway_rest_api.be.root_resource_id
  path_part   = "best_moves"
}

resource "aws_api_gateway_method" "be_chat" {
  rest_api_id   = data.aws_api_gateway_rest_api.be.id
  resource_id   = aws_api_gateway_resource.be_chat.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "be_chat" {
  rest_api_id             = data.aws_api_gateway_rest_api.be.id
  resource_id             = aws_api_gateway_resource.be_chat.id
  http_method             = aws_api_gateway_method.be_chat.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.apig_integration_arn
}

########### /best_moves OPTIONS ################
resource "aws_api_gateway_method" "be_chat_options" {
  rest_api_id   = data.aws_api_gateway_rest_api.be.id
  resource_id   = aws_api_gateway_resource.be_chat.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "be_chat_options_200" {
  rest_api_id = data.aws_api_gateway_rest_api.be.id
  resource_id = aws_api_gateway_resource.be_chat.id
  http_method = aws_api_gateway_method.be_chat_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin"  = false,
  }
}

resource "aws_api_gateway_integration" "be_chat_options" {
  rest_api_id = data.aws_api_gateway_rest_api.be.id
  resource_id = aws_api_gateway_resource.be_chat.id
  http_method = aws_api_gateway_method.be_chat_options.http_method

  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

