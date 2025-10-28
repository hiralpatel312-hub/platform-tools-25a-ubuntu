variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster name"
}
variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs from VPC module"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs from VPC module"
}

variable "worker_sg_id" {
  type        = string
  description = "Security Group ID for worker nodes"
}

variable "ec2_instance_types" {
  type        = list(string)
  description = "List of EC2 instance types for worker nodes"
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of worker nodes"
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes"
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
}
variable "sso_admin_role_arn" {
  type        = string
  description = "ARN of AWS SSO Administrator Role"
}

variable "github_runner_ci_role_arn" {
  type        = string
  description = "ARN of GitHub Actions CI Role"
}

variable "github_runner_terraform_role_arn" {
  type        = string
  description = "ARN of GitHub Actions Terraform Role"
}