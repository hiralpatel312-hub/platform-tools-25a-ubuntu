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
  depends_on = [var.aws_auth_ready]
}
# Worker node security group
resource "aws_security_group" "eks_worker_sg" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for EKS worker nodes"
  vpc_id = var.vpc_id

}

# Allow worker nodes to communicate with each other
resource "aws_security_group_rule" "worker_to_worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_worker_sg.id
  security_group_id        = aws_security_group.eks_worker_sg.id
  description              = "Allow node-to-node traffic (all protocols)"
}

# Allow inbound traffic from control plane to worker nodes (Kubelet, HTTPS)
resource "aws_security_group_rule" "control_plane_to_workers" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  description              = "Allow control plane to communicate with Kubelet"
}

resource "aws_security_group_rule" "control_plane_to_worker_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  description              = "Allow control plane HTTPS to workers"
}

# Allow all egress traffic from workers
resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_worker_sg.id
}
