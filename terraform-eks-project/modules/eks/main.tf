#########################################
# EKS Cluster
#########################################
resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = var.public_subnet_ids
    security_group_ids      = [var.worker_sg_id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  access_config {

    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role.cluster_role
  ]
}

#########################################
# Managed Add-ons
#########################################

# AWS VPC CNI Addon - Required for pod networking
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.cluster]
}

# EBS CSI Driver - for persistent storage
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_openid_connect_provider.eks,
    aws_iam_role_policy_attachment.ebs_csi_policy
  ]
}

# CoreDNS - required for internal DNS resolution
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.cluster]
}

#########################################
# Cluster Data
#########################################
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.cluster.name
}
