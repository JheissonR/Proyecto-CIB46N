resource "aws_cognito_user_pool" "main" {
  name = "migraiac-users-c02"
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "migraiac-client-c02"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_dynamodb_table" "items" {
  name         = "migraiac-items-c02"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"
  attribute {
    name = "Id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "sessions" {
  name         = "migraiac-sessions-c02"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionId"
  attribute {
    name = "SessionId"
    type = "S"
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket = "migraiac-uploads-c02"
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_iam_role" "lambda" {
  name = "migraiac-lambda-c02"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "migraiac-lambda-policy-c02"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = ["dynamodb:*", "s3:*"], Effect = "Allow", Resource = "*" }]
  })
}

resource "aws_lambda_function" "get_items" {
  function_name = "migraiac-get-items-c02"
  role          = aws_iam_role.lambda.arn
  handler       = "index.get"
  runtime       = "nodejs18.x"
  filename      = "api.zip"
}

resource "aws_lambda_function" "post_items" {
  function_name = "migraiac-post-items-c02"
  role          = aws_iam_role.lambda.arn
  handler       = "index.post"
  runtime       = "nodejs18.x"
  filename      = "api.zip"
}

resource "aws_api_gateway_rest_api" "main" {
  name = "migraiac-api-c02"
}

resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "items"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_items.invoke_arn
}

resource "aws_api_gateway_integration" "post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_items.invoke_arn
}

resource "aws_lambda_permission" "get" {
  statement_id  = "AllowGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_items.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "post" {
  statement_id  = "AllowPost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_items.function_name
  principal     = "apigateway.amazonaws.com"
}
