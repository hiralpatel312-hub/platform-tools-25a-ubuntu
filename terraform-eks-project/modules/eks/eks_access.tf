
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
  principal_arn = "arn:aws:iam::383585068161:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Administrator_a72305569e9173dc"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

#########################################
# 2. GitHub Actions CI/CD Role
#########################################

resource "aws_eks_access_entry" "github_runner_ci" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::383585068161:role/GitHubActionsTerraformIAMrole"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_runner_ci_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::383585068161:role/GitHubActionsTerraformIAMrole"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
   depends_on = [aws_eks_cluster.cluster]
}

#########################################
# 3. GitHub Actions Terraform Role (can be same as CI/CD)
#########################################

resource "aws_eks_access_entry" "github_runner_terraform" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::383585068161:role/GitHubActionsTerraformIAMrole"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_runner_terraform_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::383585068161:role/GitHubActionsTerraformIAMrole"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

#########################################
# 4. Node Group Role (Worker Nodes)
#########################################

resource "aws_eks_access_entry" "node_role_entry" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.node_role.arn
  type          = "EC2"
}

resource "aws_eks_access_policy_association" "node_role_policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.node_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSWorkerNodePolicy"

  access_scope {
    type = "cluster"
  }
}

# Attach EBS CSI policy
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}