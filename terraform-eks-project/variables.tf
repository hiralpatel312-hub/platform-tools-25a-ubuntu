variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
}

variable "aws_region" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
}

variable "k8s_version" {
  type    = string
}

variable "ec2_instance_types" {
  type    = list(string)
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
  type        = string
  description = "AWS SSO Administrator IAM role for cluster admin access"
}

variable "github_runner_ci_role_arn" {
  type        = string
  description = "GitHub Runner IAM role for CI/CD jobs"
}

variable "github_runner_terraform_role_arn" {
  type        = string
  description = "GitHub Runner IAM role for Terraform automation"
}
variable "cluster_name" {
  type        = string
  description = "EKS Cluster name"
}
variable "node_role_arn" {
  type        = string
  description = "IAM Role ARN for EKS Worker Nodes"
}