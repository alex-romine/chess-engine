locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = "us-east-2"

  base_url    = "chesstransformer.com"
  api_url     = "api.${local.base_url}"
  deploy_time = timestamp()
  stage_name  = "prd"

  base_name            = "chess-engine"
  function_name        = "${local.base_name}-lambda-function"
  lambda_arn           = "arn:aws:lambda:${local.aws_region}:${local.account_id}:function:${local.function_name}"
  apig_integration_arn = "arn:aws:apigateway:${local.aws_region}:lambda:path/2015-03-31/functions/${local.lambda_arn}/invocations"
}

############################################
# Set up Infra
############################################
resource "aws_ecr_repository" "chess_engine" {
  name                 = local.base_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
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
  timeout       = 60

  architectures = ["arm64"]
  memory_size   = 1024

  package_type = "Image"
  image_uri = "${aws_ecr_repository.chess_engine.repository_url}:latest"
  source_code_hash = filebase64sha256("../app/main.py")

  environment {
    variables = {
      SF_VERSION = "sf_16.1"
      SF_ARCH    = "armv8"
      IS_LAMBDA  = "True"
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda_best_moves" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${local.aws_region}:${local.account_id}:${data.aws_api_gateway_rest_api.be.id}/*/${aws_api_gateway_method.be_best_moves.http_method}${aws_api_gateway_resource.be_best_moves.path}"
}

###############################################
# APIG
###############################################
data "aws_api_gateway_rest_api" "be" {
  name = replace(local.api_url, ".", "-")
}

########### /best_moves POST ################
resource "aws_api_gateway_resource" "be_best_moves" {
  rest_api_id = data.aws_api_gateway_rest_api.be.id
  parent_id   = data.aws_api_gateway_rest_api.be.root_resource_id
  path_part   = "best_moves"
}

resource "aws_api_gateway_method" "be_best_moves" {
  rest_api_id   = data.aws_api_gateway_rest_api.be.id
  resource_id   = aws_api_gateway_resource.be_best_moves.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "be_best_moves" {
  rest_api_id             = data.aws_api_gateway_rest_api.be.id
  resource_id             = aws_api_gateway_resource.be_best_moves.id
  http_method             = aws_api_gateway_method.be_best_moves.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.apig_integration_arn
}

########### /best_moves OPTIONS ################
resource "aws_api_gateway_method" "be_best_moves_options" {
  rest_api_id   = data.aws_api_gateway_rest_api.be.id
  resource_id   = aws_api_gateway_resource.be_best_moves.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "be_best_moves_options_200" {
  rest_api_id = data.aws_api_gateway_rest_api.be.id
  resource_id = aws_api_gateway_resource.be_best_moves.id
  http_method = aws_api_gateway_method.be_best_moves_options.http_method
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

resource "aws_api_gateway_integration" "be_best_moves_options" {
  rest_api_id = data.aws_api_gateway_rest_api.be.id
  resource_id = aws_api_gateway_resource.be_best_moves.id
  http_method = aws_api_gateway_method.be_best_moves_options.http_method

  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

########### Lifecycle resources ################
resource "aws_api_gateway_deployment" "be" {
  rest_api_id = data.aws_api_gateway_rest_api.be.id
  stage_name = local.stage_name

  triggers = {
    main_py = filemd5("../app/main.py")
  }

  lifecycle {
    create_before_destroy = true
  }
}
