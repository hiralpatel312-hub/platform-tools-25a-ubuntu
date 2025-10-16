variable "project_name" {
  type = string
}

variable "k8s_version" {
  type = string
}

variable "subnets_list" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "ec2_types" {
  type = list
}
variable "eks_admin_principal_arn" {
  type        = string
}
variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS cluster and worker nodes will be deployed"
}
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}