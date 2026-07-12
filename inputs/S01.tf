resource "aws_s3_bucket" "data" {
  bucket = "migraiac-data-s01"
  tags = {
    Environment = "dev"
    Project     = "migraiac"
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}
