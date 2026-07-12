resource "aws_sns_topic" "events" {
  name = "migraiac-events-m08"
}

resource "aws_sqs_queue" "worker" {
  name = "migraiac-worker-m08"
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.worker.arn
}

resource "aws_iam_role" "lambda" {
  name = "migraiac-lambda-m08"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_lambda_function" "processor" {
  function_name = "migraiac-processor-m08"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "processor.zip"
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.worker.arn
  function_name    = aws_lambda_function.processor.arn
}
