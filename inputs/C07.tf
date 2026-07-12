resource "aws_kms_key" "main" {
  description             = "migraiac-kms-c07"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "main" {
  name          = "alias/migraiac-c07"
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_s3_bucket" "primary" {
  bucket = "migraiac-primary-c07"
}

resource "aws_s3_bucket" "replica" {
  bucket = "migraiac-replica-c07"
}

resource "aws_s3_bucket" "archive" {
  bucket = "migraiac-archive-c07"
}

resource "aws_s3_bucket" "logs" {
  bucket = "migraiac-logs-c07"
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "replica" {
  bucket = aws_s3_bucket.replica.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id
  rule {
    id     = "archive"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id
  rule {
    id     = "expire"
    status = "Enabled"
    expiration {
      days = 365
    }
  }
}

resource "aws_iam_role" "replication" {
  name = "migraiac-replication-c07"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "s3.amazonaws.com" } }]
  })
}

resource "aws_s3_bucket_replication_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id
  role   = aws_iam_role.replication.arn
  rule {
    id     = "replicate-all"
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.replica.arn
    }
  }
  depends_on = [aws_s3_bucket_versioning.primary]
}

resource "aws_s3_bucket_logging" "primary" {
  bucket        = aws_s3_bucket.primary.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "access/"
}

resource "aws_dynamodb_table" "metadata" {
  name         = "migraiac-metadata-c07"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ObjectKey"
  attribute {
    name = "ObjectKey"
    type = "S"
  }
}

resource "aws_sns_topic" "events" {
  name = "migraiac-s3-events-c07"
}

resource "aws_s3_bucket_notification" "primary" {
  bucket = aws_s3_bucket.primary.id
  topic {
    topic_arn = aws_sns_topic.events.arn
    events    = ["s3:ObjectCreated:*"]
  }
}
