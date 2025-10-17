resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids = var.public_subnet_ids
    endpoint_public_access = true
    endpoint_private_access = false
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# Managed addons (if supported for your chosen k8s version)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.cluster.name
  addon_name        = "vpc-cni"

  depends_on = [aws_eks_cluster.cluster]
}


resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "aws-ebs-csi-driver"
}
