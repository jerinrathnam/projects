provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["C:/Users/jerin/.aws/credentials"]
  profile                  = "jerin"
}

########################### LAMBDA FUNCTION  ##############################################


resource "aws_lambda_function" "api_gateway" {
  filename      = "index.zip"
  function_name = "APIGateway_Lambda"
  role          = "arn:aws:iam::387232581030:role/lambda-basic"
  handler       = "index.lambda_handler"

  runtime = "python3.9"
}

################# PERMISSION FOR API GATEWAY TO INVOKE LAMBDA ##############################

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateWay"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_gateway.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.MyAPI.execution_arn}/*/*/*"
}

################################## REST API GATEWAY ########################################

resource "aws_api_gateway_rest_api" "MyAPI" {
  name        = "MyAPI"
  description = "This is my API for demonstration purposes"
}

################################## REST API GATEWAY RESOURCE ################################

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.MyAPI.id
  parent_id   = aws_api_gateway_rest_api.MyAPI.root_resource_id
  path_part   = "{proxy+}"
}

################################## REST API GATEWAY METHOD ###################################

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.MyAPI.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.MyAPI.id}"
  resource_id   = "${aws_api_gateway_rest_api.MyAPI.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

################################## REST API GATEWAY INTEGRATION ##############################

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.MyAPI.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_gateway.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.MyAPI.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.api_gateway.invoke_arn}"
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

########################################## OUTPUTS ##########################################

output "base_url" {
  value = aws_api_gateway_deployment.MyAPI.invoke_url
}
