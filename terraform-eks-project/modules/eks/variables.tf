variable "project_name" { 
    type = string
    description = "Project name for tagging and resource naming"
     }
variable "environment" { 
    type = string
    description = "Environment for the EKS cluster"
     }
variable "aws_region" { 
    type = string
    description = "AWS region for EKS cluster"
     }
variable "vpc_id" { 
    type = string 
    description = "VPC ID from the vpc module"
    }
variable "public_subnet_ids" { 
    type = list(string) 
    description = "Public subnet IDs — used for control plane visibility"
    }
variable "private_subnet_ids" { 
    type = list(string) 
    description = "Private subnet IDs — worker nodes are placed here"
    }
variable "cluster_name" { 
    type = string 
     description = "EKS cluster name"
    }
variable "k8s_version" { 
    type = string 
    description = "Kubernetes version"
    }
variable "ec2_instance_types" { 
    type = list(string)
    description = "Instance types for worker nodes"
     }
variable "node_key_name" {
  type        = string
  description = "EC2 key pair name for worker nodes. Leave empty to disable SSH."
  default     = ""
}     
variable "desired_capacity" {
  type    = number
  default = 3
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 5
}

variable "github_runner_terraform_role_arn" { 
    type = string 
    description = "ARN of the IAM role for GitHub Actions runner access to EKS"
    }