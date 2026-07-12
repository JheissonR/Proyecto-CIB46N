resource "aws_kinesis_stream" "ingest" {
  name        = "migraiac-ingest-c04"
  shard_count = 2
}

resource "aws_s3_bucket" "raw" {
  bucket = "migraiac-raw-c04"
}

resource "aws_s3_bucket" "processed" {
  bucket = "migraiac-processed-c04"
}

resource "aws_s3_bucket" "curated" {
  bucket = "migraiac-curated-c04"
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_iam_role" "firehose" {
  name = "migraiac-firehose-c04"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "glue" {
  name = "migraiac-glue-c04"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "glue.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "lambda" {
  name = "migraiac-lambda-c04"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "s3" {
  name        = "migraiac-firehose-c04"
  destination = "extended_s3"
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.raw.arn
  }
}

resource "aws_glue_catalog_database" "main" {
  name = "migraiac_catalog_c04"
}

resource "aws_glue_crawler" "raw" {
  name          = "migraiac-crawler-c04"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.main.name
  s3_target {
    path = "s3://${aws_s3_bucket.raw.id}"
  }
}

resource "aws_glue_job" "transform" {
  name     = "migraiac-transform-c04"
  role_arn = aws_iam_role.glue.arn
  command {
    script_location = "s3://${aws_s3_bucket.processed.id}/scripts/transform.py"
  }
}

resource "aws_lambda_function" "trigger" {
  function_name = "migraiac-trigger-c04"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "trigger.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/migraiac-trigger-c04"
  retention_in_days = 7
}

resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn  = aws_kinesis_stream.ingest.arn
  function_name     = aws_lambda_function.trigger.arn
  starting_position = "LATEST"
}

resource "aws_athena_workgroup" "main" {
  name = "migraiac-athena-c04"
}
