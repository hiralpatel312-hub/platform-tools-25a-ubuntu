#########################################################
# 1. EKS Cluster
#########################################################

resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = var.public_subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [
    aws_iam_role.cluster_role,
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

#########################################################
# 2. Managed Add-ons
#########################################################

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_cluster.cluster]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_openid_connect_provider.eks,
    aws_iam_role_policy_attachment.ebs_csi_policy
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_cluster.cluster]
}
