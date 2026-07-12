resource "aws_kinesis_stream" "events" {
  name        = "migraiac-stream-m13"
  shard_count = 1
}

resource "aws_s3_bucket" "data" {
  bucket = "migraiac-stream-data-m13"
}

resource "aws_iam_role" "lambda" {
  name = "migraiac-stream-lambda-m13"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "migraiac-stream-policy-m13"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = ["kinesis:GetRecords", "s3:PutObject"], Effect = "Allow", Resource = "*" }]
  })
}

resource "aws_lambda_function" "processor" {
  function_name = "migraiac-stream-processor-m13"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "processor.zip"
}

resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn  = aws_kinesis_stream.events.arn
  function_name     = aws_lambda_function.processor.arn
  starting_position = "LATEST"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/migraiac-stream-processor-m13"
  retention_in_days = 7
}
