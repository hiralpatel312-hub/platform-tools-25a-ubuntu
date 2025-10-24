data "aws_availability_zones" "azs" {
  state = "available"
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  cidr_block   = var.vpc_cidr
  region       = var.aws_region
  azs          = slice(data.aws_availability_zones.azs.names, 0, 3)
}

module "eks" {
  source                 = "./modules/eks"
  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  k8s_version            = var.k8s_version
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_subnet_ids     = module.vpc.private_subnet_ids
  vpc_id                 = module.vpc.vpc_id
  ec2_instance_types     = var.ec2_instance_types
  desired_capacity       = var.desired_capacity
  min_size               = var.min_size
  max_size               = var.max_size
}
