# ------------------------------
# EKS Cluster
# ------------------------------
resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version
  
   access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
  vpc_config {
    subnet_ids = concat(
      var.private_subnet_ids, # nodes live in private subnets
      var.public_subnet_ids   # control plane needs both for multi-AZ
    )
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
  }
}

# ------------------------------
# Wait for Cluster creation
# ------------------------------
resource "time_sleep" "wait_for_cluster" {
  depends_on      = [aws_eks_cluster.cluster]
  create_duration = "300s" # min to ensure cluster is ready
}

# ------------------------------
# OIDC Provider (for IRSA)
# ------------------------------
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = {
    Name        = "${var.project_name}-${var.environment}-oidc"
    Environment = var.environment
  }
}
#################################################
# EKS Add-Ons
#################################################

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "vpc-cni"
  addon_version = "v1.21.1-eksbuild.7" 
  depends_on    = [time_sleep.wait_for_cluster]
  tags = {
    Environment = var.environment
  }
}
resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "kube-proxy"
  addon_version = "v1.32.13-eksbuild.5"
  depends_on    = [time_sleep.wait_for_cluster, aws_eks_addon.vpc_cni]
  tags = {
    Environment = var.environment
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "coredns"
  addon_version = "v1.11.4-eksbuild.33" 
  depends_on    = [time_sleep.wait_for_cluster, aws_eks_addon.vpc_cni, aws_autoscaling_group.nodes_asg]
  tags = {
    Environment = var.environment
  }
}


resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.57.1-eksbuild.1" 
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
  depends_on = [time_sleep.wait_for_cluster,
    aws_eks_addon.vpc_cni,
    aws_autoscaling_group.nodes_asg,
    aws_iam_openid_connect_provider.eks,
  aws_iam_role_policy_attachment.ebs_csi_policy]
  tags = {
    Environment = var.environment
  }
}