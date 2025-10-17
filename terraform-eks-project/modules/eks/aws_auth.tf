# Data sources for kubeconfig and cluster
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.cluster.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Build mapRoles list with node role + admin roles
locals {
  # NOTE: using locals only inside this one file to build YAML string for aws-auth
  map_roles = [
    {
      rolearn  = aws_iam_role.node_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers","system:nodes"]
    },
  ]
  # Add admin and github runner roles only if set
  map_roles_extended = concat(
    local.map_roles,
    var.admin_role_arn != "" ? [
      {
        rolearn  = var.admin_role_arn
        username = replace(var.admin_role_arn, "arn:aws:iam::[0-9]+:role/", "")
        groups   = ["system:masters"]
      }
    ] : [],
    var.github_runner_role_arn != "" ? [
      {
        rolearn  = var.github_runner_role_arn
        username = replace(var.github_runner_role_arn, "arn:aws:iam::[0-9]+:role/", "")
        groups   = ["system:masters"]
      }
    ] : []
  )
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.map_roles_extended)
  }

  depends_on = [aws_autoscaling_group.nodes_asg]
}
