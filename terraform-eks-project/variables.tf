variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region for EKS cluster and related resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version for EKS cluster"
}


variable "ec2_instance_types" {
  type        = list(string)
  description = "List of EC2 instance types for EKS worker nodes"
}

variable "node_key_name" {
  type        = string
  description = "EC2 key pair name for worker nodes. Leave empty to disable SSH."
  default     = ""
}

variable "desired_capacity" {
  type        = number
  default     = 3
  description = "Desired capacity for the EKS worker node group"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum size for the EKS worker node group"
}

variable "max_size" {
  type        = number
  default     = 5
  description = "Maximum size for the EKS worker node group"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "sso_admin_role_arn" {
  type        = string
  description = "SSO Admin role ARN"
}

variable "github_runner_terraform_role_arn" {
  type        = string
  description = "GitHub Runner Terraform role ARN"
}

variable "github_runner_ci_role_arn" {
  type        = string
  description = "GitHub Runner CI role ARN"
}
variable "node_role_arn" {
  type        = string
  description = "IAM Role ARN for EKS worker nodes"
}
