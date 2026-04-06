output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}
output "cluster" {
  value = aws_eks_cluster.cluster
}
output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "node_role_arn" {
  value = aws_iam_role.node_role.arn
}
output "worker_asg_name" {
  value = aws_autoscaling_group.nodes_asg.name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — used for IRSA role bindings"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "ebs_csi_role_arn" {
  description = "EBS CSI driver IRSA role ARN"
  value       = aws_iam_role.ebs_csi_role.arn
}