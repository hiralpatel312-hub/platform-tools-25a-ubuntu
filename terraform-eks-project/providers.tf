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
provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.cluster.name
}

