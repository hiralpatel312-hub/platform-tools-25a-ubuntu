#########################################
# 1. AWS SSO Administrator Access
#########################################

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

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_cluster.cluster]
}

#########################################
# 2. GitHub Actions Role (CI/CD + Terraform)
#########################################

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

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_runner]
}

#########################################
# 3. Node Group Role (Worker Nodes)
#########################################

resource "aws_eks_access_entry" "node_role_entry" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.node_role.arn
  type          = "EC2"

  depends_on = [aws_eks_cluster.cluster]
}

resource "aws_eks_access_policy_association" "node_role_policy" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = aws_iam_role.eks_node_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.node_role_entry]
}
