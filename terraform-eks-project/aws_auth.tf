resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = var.github_runner_terraform_role_arn
        username = "github-runner"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [aws_eks_node_group.node_group]
}
