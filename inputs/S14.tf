resource "aws_s3_bucket" "archive" {
  bucket = "migraiac-archive-s14"
}

resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id
  rule {
    id     = "expire-old"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}
