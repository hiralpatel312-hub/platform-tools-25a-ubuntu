resource "null_resource" "aws_auth" {
  provisioner "local-exec" {
    command = <<EOT
      # Add EKS node role
      eksctl create iamidentitymapping \
        --cluster ${module.eks.cluster_name} \
        --region ${var.aws_region} \
        --arn ${module.eks.node_role_arn} \
        --username system:node:{{EC2PrivateDNSName}} \
        --group system:bootstrappers \
        --approve

      # Add GitHub Actions role
      eksctl create iamidentitymapping \
        --cluster ${module.eks.cluster_name} \
        --region ${var.aws_region} \
        --arn ${var.github_runner_ci_role_arn} \
        --username github-runner \
        --group system:masters \
        --approve
    EOT

    environment = {
      AWS_REGION = var.aws_region
    }
  }

  depends_on = [module.eks]
}
