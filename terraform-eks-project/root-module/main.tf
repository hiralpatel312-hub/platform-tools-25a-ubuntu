module "kubernetes_cluster" {
  source        = "../eks-module"
  k8s_version   = var.root_k8s_version
  subnets_list  = module.main_vpc.subnet_ids
  clustername   = var.root_cluster_name
  environment   = var.root_environment
  project_name  = var.root_project_name
}

module "main_vpc" {
  source            = "../vpc-module"
  cidr_block_prefix = "10.7"
  project_name      = var.root_project_name
}