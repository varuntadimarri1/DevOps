provider "aws" {
  region = "us-east-1"
}

# Create S3 bucket to store remote state file #
resource "aws_s3_bucket" "example" {
  bucket = "practice-demo-s3"
}

# Create a dynamodb table for locking the state file #
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "terraform-state-lock-dynamo"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}



