resource "time_sleep" "wait_for_cluster" {
  create_duration = "300s"
  depends_on      = [aws_eks_cluster.cluster]
}

# SSO Admin
resource "aws_eks_access_entry" "sso_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = var.sso_admin_role_arn
  type          = "STANDARD"
  depends_on    = [time_sleep.wait_for_cluster]
}

resource "aws_eks_access_policy_association" "sso_admin_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_eks_access_entry.sso_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# GitHub Actions
resource "aws_eks_access_entry" "github_runner" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = var.github_runner_terraform_role_arn
}

resource "aws_eks_access_policy_association" "github_runner_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_eks_access_entry.github_runner.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "node_role_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.node_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
