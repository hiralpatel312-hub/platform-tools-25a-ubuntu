data "aws_availability_zones" "azs" {
  state = "available"
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  region       = var.aws_region
  azs          = slice(data.aws_availability_zones.azs.names, 0, 3)
  cidr_block   = var.vpc_cidr
}

module "eks" {
  source                 = "./modules/eks"
  project_name           = var.project_name
  environment            = var.environment
  k8s_version            = var.k8s_version
  worker_sg_id        = module.vpc.eks_worker_sg_id  
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_subnet_ids     = module.vpc.private_subnet_ids
  ec2_instance_types     = var.ec2_instance_types
  desired_capacity       = var.desired_capacity
  min_size               = var.min_size
  max_size               = var.max_size
}
