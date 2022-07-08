provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["C:/Users/jerin/.aws/credentials"]
  profile                  = "jerin"
}

########################### LAMBDA FUNCTION  ####################################

resource "aws_lambda_function" "api_gateway" {
  function_name = "lambda_function_name"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
}

######################## ALIAS FOR LAMBDA FUNCTION #############################

resource "aws_lambda_alias" "lambda_alias" {
  name             = "lambdaalias"
  function_name    = aws_lambda_function.api_gateway.function_name
  function_version = "$LATEST"
}

################# PERMISSION FOR API GATEWAY TO INVOKE LAMBDA ###################

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateWay"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_gateway.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.MyAPI.execution_arn}/*/*/*"
}

####################### IAM ROLE FOR LAMBDA FUNCTION ############################

resource "aws_iam_role" "lambda_exec" {
  name = "ApiGateway_lambda"

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

################################## REST API GATEWAY ##############################

resource "aws_api_gateway_rest_api" "MyAPI" {
  name        = "MyAPI"
  description = "This is my API for demonstration purposes"
}

################################## REST API GATEWAY RESOURCE ##############################

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.MyAPI.id
  parent_id   = aws_api_gateway_rest_api.MyAPI.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.MyAPI.id
  resource_id   = aws_api_gateway_rest_api.MyAPI.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

################################## REST API GATEWAY METHOD ##############################

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.MyAPI.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

################################## REST API GATEWAY INTEGRATION ##############################

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.MyAPI.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_gateway.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.MyAPI.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_gateway.invoke_arn
}

################################## REST API GATEWAY DEPLOYMENT ##############################

resource "aws_api_gateway_deployment" "MyAPI" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.MyAPI.id
  stage_name  = "test"
}

################################## OUTPUTS ##############################

output "base_url" {
  value = aws_api_gateway_deployment.MyAPI.invoke_url
}