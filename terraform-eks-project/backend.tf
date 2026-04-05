terraform {
  backend "s3" {
    bucket         = "099695389768-state-bucket-dev1"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraformlock"
  }
}
