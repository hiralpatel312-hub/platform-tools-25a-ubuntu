#########################################################
# 1. AWS SSO Admin Access
#########################################################

resource "aws_eks_access_entry" "sso_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::383585068161:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Administrator_a72305569e9173dc"
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.cluster]
}

resource "aws_eks_access_policy_association" "sso_admin_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_eks_access_entry.sso_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope { type = "cluster" }
  depends_on    = [aws_eks_access_entry.sso_admin]
}

#########################################################
# 2. GitHub Actions Role
#########################################################

resource "aws_eks_access_entry" "github_runner" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::383585068161:role/GitHubActionsTerraformIAMrole"
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.cluster]
}

resource "aws_eks_access_policy_association" "github_runner_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_eks_access_entry.github_runner.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope { type = "cluster" }
    depends_on    = [aws_eks_access_entry.github_runner]
  }
