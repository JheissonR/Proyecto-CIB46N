resource "aws_iam_role" "lambda" {
  name = "migraiac-lambda-m04"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "migraiac-lambda-policy-m04"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = ["dynamodb:PutItem", "dynamodb:GetItem"], Effect = "Allow", Resource = aws_dynamodb_table.data.arn }]
  })
}

resource "aws_dynamodb_table" "data" {
  name         = "migraiac-data-m04"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"
  attribute {
    name = "Id"
    type = "S"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/migraiac-fn-m04"
  retention_in_days = 7
}

resource "aws_lambda_function" "fn" {
  function_name = "migraiac-fn-m04"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "function.zip"
  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.data.name }
  }
}

resource "aws_sqs_queue" "events" {
  name                       = "migraiac-events-m04"
  visibility_timeout_seconds = 30
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.events.arn
  function_name    = aws_lambda_function.fn.arn
  batch_size       = 10
}
