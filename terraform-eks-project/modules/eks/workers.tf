resource "aws_iam_instance_profile" "node_profile" {
  name = "${var.project_name}-${var.environment}-node-profile"
  role = aws_iam_role.node_role.name
}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.k8s_version}/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "nodes_lt" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = element(var.ec2_instance_types, 0)

  iam_instance_profile {
    name = aws_iam_instance_profile.node_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/bootstrap.sh.tpl", {
    cluster_name = var.cluster_name
  }))

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "nodes_asg" {
  name                = "${var.project_name}-${var.environment}-nodes-asg"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.nodes_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  # Ensure aws-auth is applied first
  depends_on = [kubernetes_config_map.aws_auth]
}
