output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "node_asg_name" {
  value = aws_autoscaling_group.nodes_asg.name
}
