terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.18.0, < 7.0.0"
    }
  }
  required_version = ">= 1.13.4"
}


provider "aws" {
  region = "us-east-1"
}
