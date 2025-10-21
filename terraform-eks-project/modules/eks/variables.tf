variable "project_name" {
     type = string 
}
variable "environment" { 
    type = string 
}
variable "aws_region" { 
    type = string 
}
variable "k8s_version" { 
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
variable "ec2_instance_types" { 
    type = list(string) 
}
variable "desired_capacity" { 
    type = number 
}
variable "min_size" { 
    type = number 
}
variable "max_size" { 
    type = number 
}
variable "admin_role_arn" {
  description = "AWS SSO Administrator role ARN for cluster admin access"
  type        = string
  default     = ""
}

variable "github_runner_role_arn" {
  description = "GitHub Actions application CI/CD IAM role ARN"
  type        = string
  default     = ""
}

variable "github_tf_role_arn" {
  description = "GitHub Actions Terraform IAM role ARN"
  type        = string
  default     = ""
}
