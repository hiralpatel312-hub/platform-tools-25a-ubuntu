terraform {
  backend "s3" {
    bucket         = "383585068161-state-bucket-dev"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraformlock"
  }
}
