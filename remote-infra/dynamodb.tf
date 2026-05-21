resource "aws_dynamodb_table" "state-dynamodb-table" {
  name           = "tf_state_lock_dynamodb"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "tf_state_lock_dynamodb"
  }
}