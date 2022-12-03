terraform {
  backend "s3" {
    bucket         = "practice-demo-s3"
    key            = "default/terraform.tfstate" # path & file which will hold the state #
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo" # dynamoDB to store state lock #
    encrypt        = "true"
  }
}

