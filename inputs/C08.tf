resource "aws_iam_role" "lambda" {
  name = "migraiac-lambda-c08"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "sfn" {
  name = "migraiac-sfn-c08"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "states.amazonaws.com" } }]
  })
}

resource "aws_dynamodb_table" "orders" {
  name         = "migraiac-orders-c08"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "OrderId"
  attribute {
    name = "OrderId"
    type = "S"
  }
}

resource "aws_sqs_queue" "orders" {
  name = "migraiac-orders-c08"
}

resource "aws_sqs_queue" "dlq" {
  name = "migraiac-dlq-c08"
}

resource "aws_sns_topic" "notifications" {
  name = "migraiac-notifications-c08"
}

resource "aws_lambda_function" "validate" {
  function_name = "migraiac-validate-c08"
  role          = aws_iam_role.lambda.arn
  handler       = "index.validate"
  runtime       = "nodejs18.x"
  filename      = "fn.zip"
}

resource "aws_lambda_function" "process" {
  function_name = "migraiac-process-c08"
  role          = aws_iam_role.lambda.arn
  handler       = "index.process"
  runtime       = "nodejs18.x"
  filename      = "fn.zip"
}

resource "aws_lambda_function" "notify" {
  function_name = "migraiac-notify-c08"
  role          = aws_iam_role.lambda.arn
  handler       = "index.notify"
  runtime       = "nodejs18.x"
  filename      = "fn.zip"
}

resource "aws_cloudwatch_event_rule" "orders" {
  name                = "migraiac-orders-rule-c08"
  event_pattern = jsonencode({
    source = ["migraiac.orders"]
  })
}

resource "aws_cloudwatch_event_target" "validate" {
  rule      = aws_cloudwatch_event_rule.orders.name
  target_id = "validate"
  arn       = aws_lambda_function.validate.arn
}

resource "aws_sfn_state_machine" "order_flow" {
  name     = "migraiac-order-flow-c08"
  role_arn = aws_iam_role.sfn.arn
  definition = jsonencode({
    Comment = "Order processing"
    StartAt = "Validate"
    States = {
      Validate = {
        Type     = "Task"
        Resource = aws_lambda_function.validate.arn
        Next     = "Process"
      }
      Process = {
        Type     = "Task"
        Resource = aws_lambda_function.process.arn
        End      = true
      }
    }
  })
}

resource "aws_lambda_event_source_mapping" "orders" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.process.arn
}

resource "aws_cloudwatch_log_group" "validate" {
  name              = "/aws/lambda/migraiac-validate-c08"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "process" {
  name              = "/aws/lambda/migraiac-process-c08"
  retention_in_days = 7
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validate.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.orders.arn
}

resource "aws_sqs_queue_policy" "orders" {
  queue_url = aws_sqs_queue.orders.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = "*", Action = "sqs:SendMessage", Resource = aws_sqs_queue.orders.arn }]
  })
}
