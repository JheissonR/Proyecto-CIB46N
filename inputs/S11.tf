resource "aws_dynamodb_table" "users" {
  name         = "migraiac-users-s11"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}
