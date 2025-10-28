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
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
