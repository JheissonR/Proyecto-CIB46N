resource "aws_kinesis_stream" "telemetry" {
  name        = "migraiac-telemetry-c12"
  shard_count = 4
}

resource "aws_s3_bucket" "raw" {
  bucket = "migraiac-telemetry-raw-c12"
}

resource "aws_dynamodb_table" "devices" {
  name         = "migraiac-devices-c12"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "DeviceId"
  attribute {
    name = "DeviceId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "state" {
  name         = "migraiac-state-c12"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "DeviceId"
  range_key    = "Timestamp"
  attribute {
    name = "DeviceId"
    type = "S"
  }
  attribute {
    name = "Timestamp"
    type = "N"
  }
}

resource "aws_iam_role" "lambda" {
  name = "migraiac-lambda-c12"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "migraiac-lambda-policy-c12"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = ["dynamodb:*", "kinesis:*", "s3:*"], Effect = "Allow", Resource = "*" }]
  })
}

resource "aws_lambda_function" "ingest" {
  function_name = "migraiac-ingest-c12"
  role          = aws_iam_role.lambda.arn
  handler       = "index.ingest"
  runtime       = "python3.11"
  filename      = "ingest.zip"
}

resource "aws_lambda_function" "aggregate" {
  function_name = "migraiac-aggregate-c12"
  role          = aws_iam_role.lambda.arn
  handler       = "index.aggregate"
  runtime       = "python3.11"
  filename      = "aggregate.zip"
}

resource "aws_lambda_function" "alert" {
  function_name = "migraiac-alert-c12"
  role          = aws_iam_role.lambda.arn
  handler       = "index.alert"
  runtime       = "python3.11"
  filename      = "alert.zip"
}

resource "aws_lambda_event_source_mapping" "ingest" {
  event_source_arn  = aws_kinesis_stream.telemetry.arn
  function_name     = aws_lambda_function.ingest.arn
  starting_position = "LATEST"
}

resource "aws_sns_topic" "alerts" {
  name = "migraiac-device-alerts-c12"
}

resource "aws_sqs_queue" "processing" {
  name = "migraiac-processing-c12"
}

resource "aws_cloudwatch_log_group" "ingest" {
  name              = "/aws/lambda/migraiac-ingest-c12"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "aggregate" {
  name              = "/aws/lambda/migraiac-aggregate-c12"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "iterator_age" {
  alarm_name          = "migraiac-iterator-age-c12"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "IteratorAge"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Maximum"
  threshold           = 60000
}

resource "aws_iam_role" "firehose" {
  name = "migraiac-firehose-c12"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" } }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "archive" {
  name        = "migraiac-archive-c12"
  destination = "extended_s3"
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.raw.arn
  }
}
