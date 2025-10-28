# Add this null_resource delay before EKS access entries
resource "null_resource" "wait_for_auth_mode" {
  depends_on = [aws_eks_cluster.cluster]

  provisioner "local-exec" {
    # Wait a bit to ensure cluster auth mode is active
    command = "sleep 60"
  }
}
#########################################
# 1. AWS SSO Administrator Access
#########################################
resource "aws_eks_access_entry" "sso_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::383585068161:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Administrator_a72305569e9173dc"
  type          = "STANDARD"

  depends_on = [null_resource.wait_for_auth_mode]
}

resource "aws_eks_access_policy_association" "sso_admin_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_eks_access_entry.sso_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope { type = "cluster" }

  depends_on = [aws_eks_access_entry.sso_admin]
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

  access_scope { type = "cluster" }

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
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.node_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope { type = "cluster" }
}
