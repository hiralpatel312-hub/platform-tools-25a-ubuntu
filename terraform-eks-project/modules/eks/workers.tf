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
  CLUSTER_NAME     = aws_eks_cluster.cluster.name
  CLUSTER_ENDPOINT = aws_eks_cluster.cluster.endpoint
  CLUSTER_CA       = aws_eks_cluster.cluster.certificate_authority[0].data
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

 # Security group for EKS cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  vpc_id      = var.vpc_id
  description = "EKS cluster security group"
}

# Worker node security group
resource "aws_security_group" "eks_worker_sg" {
  name        = "${var.project_name}-${var.environment}-worker-sg"
  vpc_id      = var.vpc_id
}

# Allow cluster to communicate with worker nodes
resource "aws_security_group_rule" "cluster_to_worker_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "worker_to_cluster" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
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