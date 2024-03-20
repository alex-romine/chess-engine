# To create your own APIG, uncomment this file and comment out the APIG in main.tf

###############################################
# APIG
###############################################
# resource "aws_api_gateway_rest_api" "be" {
#   name = local.base_name

#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# ########### /healthz ################
# resource "aws_api_gateway_resource" "be_healthz" {
#   rest_api_id = aws_api_gateway_rest_api.be.id
#   parent_id   = aws_api_gateway_rest_api.be.root_resource_id
#   path_part   = "healthz"
# }

# resource "aws_api_gateway_method" "be_healthz" {
#   rest_api_id   = aws_api_gateway_rest_api.be.id
#   resource_id   = aws_api_gateway_resource.be_healthz.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "be_healthz" {
#   rest_api_id             = aws_api_gateway_rest_api.be.id
#   resource_id             = aws_api_gateway_resource.be_healthz.id
#   http_method             = aws_api_gateway_method.be_healthz.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = local.apig_integration_arn
# }

# ########### /best_moves POST ################
# resource "aws_api_gateway_resource" "be_chat" {
#   rest_api_id = aws_api_gateway_rest_api.be.id
#   parent_id   = aws_api_gateway_rest_api.be.root_resource_id
#   path_part   = "best_moves"
# }

# resource "aws_api_gateway_method" "be_chat" {
#   rest_api_id   = aws_api_gateway_rest_api.be.id
#   resource_id   = aws_api_gateway_resource.be_chat.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "be_chat" {
#   rest_api_id             = aws_api_gateway_rest_api.be.id
#   resource_id             = aws_api_gateway_resource.be_chat.id
#   http_method             = aws_api_gateway_method.be_chat.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = local.apig_integration_arn
# }

# ########### /best_moves OPTIONS ################
# resource "aws_api_gateway_method" "be_chat_options" {
#   rest_api_id   = aws_api_gateway_rest_api.be.id
#   resource_id   = aws_api_gateway_resource.be_chat.id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_method_response" "be_chat_options_200" {
#   rest_api_id = aws_api_gateway_rest_api.be.id
#   resource_id = aws_api_gateway_resource.be_chat.id
#   http_method = aws_api_gateway_method.be_chat_options.http_method
#   status_code = "200"

#   response_models = {
#     "application/json" = "Empty"
#   }

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = false,
#     "method.response.header.Access-Control-Allow-Methods" = false,
#     "method.response.header.Access-Control-Allow-Origin"  = false,
#   }
# }

# resource "aws_api_gateway_integration" "be_chat_options" {
#   rest_api_id = aws_api_gateway_rest_api.be.id
#   resource_id = aws_api_gateway_resource.be_chat.id
#   http_method = aws_api_gateway_method.be_chat_options.http_method

#   type                 = "MOCK"
#   passthrough_behavior = "WHEN_NO_MATCH"
#   request_templates = {
#     "application/json" = "{\"statusCode\": 200}"
#   }
# }

# ########### Lifecycle resources ################
# resource "aws_api_gateway_deployment" "be" {
#   rest_api_id = aws_api_gateway_rest_api.be.id

#   triggers = {
#     redeployment = timestamp()
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_api_gateway_stage" "be" {
#   deployment_id = aws_api_gateway_deployment.be.id
#   rest_api_id   = aws_api_gateway_rest_api.be.id
#   stage_name    = "prd"
# }

# ############################################
# # DNS
# ############################################
# data "aws_route53_zone" "chess_zone" {
#   name = local.base_url
# }

# # This cert created manually
# data "aws_acm_certificate" "be" {
#   domain = local.base_url
#   types  = ["AMAZON_ISSUED"]
# }

# resource "aws_api_gateway_domain_name" "be" {
#   regional_certificate_arn = data.aws_acm_certificate.be.arn
#   domain_name              = local.api_url

#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# resource "aws_api_gateway_base_path_mapping" "be" {
#   api_id      = aws_api_gateway_rest_api.be.id
#   stage_name  = aws_api_gateway_stage.be.stage_name
#   domain_name = aws_api_gateway_domain_name.be.domain_name
# }

# resource "aws_route53_record" "chess_be" {
#   zone_id = data.aws_route53_zone.chess_zone.zone_id
#   name    = local.api_url
#   type    = "A"

#   alias {
#     evaluate_target_health = true
#     name                   = aws_api_gateway_domain_name.be.regional_domain_name
#     zone_id                = aws_api_gateway_domain_name.be.regional_zone_id
#   }
# }
