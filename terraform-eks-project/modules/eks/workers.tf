#########################################
# Worker Nodes - Launch Template & ASG
#########################################
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
    cluster_name       = var.cluster_name
    cluster_endpoint   = aws_eks_cluster.cluster.endpoint
    cluster_ca         = aws_eks_cluster.cluster.certificate_authority[0].data
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
}
#########################################
# Security Group Rules for Worker Nodes
#########################################
# Node-to-node
resource "aws_security_group_rule" "worker_to_worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_worker_sg.id
  security_group_id        = aws_security_group.eks_worker_sg.id
}

# Control plane to worker Kubelet
resource "aws_security_group_rule" "control_plane_to_workers" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = var.cluster_security_group_id
  security_group_id        = aws_security_group.eks_worker_sg.id
}

# Control plane HTTPS
resource "aws_security_group_rule" "control_plane_to_worker_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.cluster_security_group_id
  security_group_id        = aws_security_group.eks_worker_sg.id
}

# Worker egress
resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_worker_sg.id
}