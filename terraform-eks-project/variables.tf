variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
}

variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
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

variable "cluster_name" {
  type = string
}

variable "sso_admin_role_arn" {
  type = string
}

variable "github_runner_terraform_role_arn" {
  type = string
}

variable "github_runner_ci_role_arn" {
  type = string
}
