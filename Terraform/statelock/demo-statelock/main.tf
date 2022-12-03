provider "aws" {
  region = "us-east-1"
}

# Specify the EC2 details
resource "aws_instance" "example" {
  ami           = "ami-0b0dcb5067f052a63"
  instance_type = "t2.micro"
}
