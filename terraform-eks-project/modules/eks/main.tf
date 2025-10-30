# ------------------------------
# EKS Cluster
# ------------------------------
resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids             = var.public_subnet_ids
    endpoint_public_access = true
    endpoint_private_access = false
  }

  # Authentication mode must include CONFIG_MAP for access entries
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
}

# ------------------------------
# Wait for Cluster creation
# ------------------------------
resource "time_sleep" "wait_for_cluster" {
  depends_on      = [aws_eks_cluster.cluster]
  create_duration = "60s"  # Wait 1 min to ensure cluster is ready
}

# ------------------------------
# OIDC Provider (for IRSA)
# ------------------------------
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10ebc"]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# ------------------------------
# Managed Add-ons
# ------------------------------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
  depends_on   = [time_sleep.wait_for_cluster]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "coredns"
  depends_on   = [time_sleep.wait_for_cluster]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "aws-ebs-csi-driver"
  depends_on   = [time_sleep.wait_for_cluster]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "kube-proxy"
  depends_on   = [time_sleep.wait_for_cluster]
}
