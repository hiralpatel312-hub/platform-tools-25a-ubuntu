# ------------------------------
# EKS Cluster
# ------------------------------
resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = var.public_subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }
}

# ------------------------------
# Wait for Cluster creation
# ------------------------------
resource "time_sleep" "wait_for_cluster" {
  depends_on      = [aws_eks_cluster.cluster]
  create_duration = "300s"  # min to ensure cluster is ready
}

# ------------------------------
# OIDC Provider (for IRSA)
# ------------------------------
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10ebc"]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
############################################
# EKS Add-ons (Latest Compatible Versions)
############################################

# Automatically use the latest compatible version of aws-ebs-csi-driver
data "aws_eks_addon_version" "ebs_csi_latest" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name      = aws_eks_cluster.cluster.name
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = data.aws_eks_addon_version.ebs_csi_latest.version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.cluster.name
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.cluster.name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
}
