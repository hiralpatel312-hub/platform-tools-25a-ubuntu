variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the cluster"
  type        = list(string)
}
variable "private_subnet_ids" {
  description = "List of private subnet IDs for the worker nodes"
  type        = list(string)
}
variable "ec2_instance_types" {
  description = "List of EC2 instance types for worker nodes"
  type        = list(string)
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
}

variable "min_size" {
  description = "ASG minimum size"
  type        = number
}

variable "max_size" {
  description = "ASG maximum size"
  type        = number
}
