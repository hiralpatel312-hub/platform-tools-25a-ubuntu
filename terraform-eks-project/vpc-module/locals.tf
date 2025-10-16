locals {
  vpc_cidr        = "${var.cidr_block_prefix}.0.0/16"
  vpc_name        = "${var.project_name}-network"
  subnet_a_cidr   = "${var.cidr_block_prefix}.1.0/24"
  subnet_b_cidr   = "${var.cidr_block_prefix}.2.0/24"
  subnet_a_tag    = "Public Subnet A"
  subnet_b_tag    = "Public Subnet B"
  ig_tag          = "${var.project_name} IG"
  route_table_tag = "adapt-ex public subnets route table"
}
