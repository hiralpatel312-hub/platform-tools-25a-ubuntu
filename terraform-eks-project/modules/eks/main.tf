resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids = var.public_subnet_ids
    endpoint_public_access = true
    endpoint_private_access = false
  }
 access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role.cluster_role,
    aws_iam_role_policy_attachment.cluster_policy,
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
# Managed addons 
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_cluster.cluster]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "aws-ebs-csi-driver"

  #  EBS CSI needs IAM OIDC provider & policy attached
  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_openid_connect_provider.eks,
    aws_iam_role_policy_attachment.ebs_csi_policy
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "coredns"

  depends_on = [aws_eks_cluster.cluster]
}
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.cluster.name
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer_thumbprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
