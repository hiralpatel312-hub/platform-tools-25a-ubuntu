variable "project_name" { 
    type = string
     }
variable "environment" { 
    type = string
     }
variable "aws_region" { 
    type = string
     }
variable "vpc_id" { 
    type = string 
    }
variable "public_subnet_ids" { 
    type = list(string) 
    }
variable "private_subnet_ids" { 
    type = list(string) 
    }
variable "cluster_name" { 
    type = string 
    }
variable "k8s_version" { 
    type = string 
    }
variable "ec2_instance_types" { 
    type = list(string)
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

variable "sso_admin_role_arn" { 
    type = string 
    }
variable "github_runner_terraform_role_arn" { 
    type = string 
    }

variable "cluster_security_group_id" {
  type        = string
  description = "Security group ID for EKS control plane"
}