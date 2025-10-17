variable "project_name" {
  type        = string
  description = "Project name prefix"
  default     = "eks-demo"
}

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
  default     = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "k8s_version" {
  type    = string
  default = "1.29" # choose one release prior to latest as required
}

variable "ec2_instance_types" {
  type    = list(string)
  default = ["t3.medium", "t3a.medium"]
}

variable "admin_role_arn" {
  type        = string
  description = "AWS SSO Administrator role ARN to map as cluster admin"
  default     = ""
}

variable "github_runner_role_arn" {
  type        = string
  description = "GitHub Runner IAM role ARN to map for CI/CD tasks"
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
