# ─────────────────────────────────────────────
# Latest EKS-optimised AMI
# ─────────────────────────────────────────────
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.k8s_version}/amazon-linux-2/recommended/image_id"
}

# ─────────────────────────────────────────────
# Launch Template
# ─────────────────────────────────────────────
resource "aws_launch_template" "nodes_lt" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = var.ec2_instance_types[0]
  key_name      = var.node_key_name != "" ? var.node_key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.node_profile.name
  }

  # FIXED: your original had no vpc_security_group_ids here.
  # Without this the launch template uses the default SG, not the
  # worker SG — so none of the security group rules you defined had
  # any effect on the actual nodes.
  vpc_security_group_ids = [aws_security_group.eks_worker_sg.id]

  user_data = base64encode(templatefile("${path.module}/bootstrap.sh.tpl", {
    CLUSTER_NAME       = aws_eks_cluster.cluster.name
    CLUSTER_ENDPOINT   = aws_eks_cluster.cluster.endpoint
    CLUSTER_CA         = aws_eks_cluster.cluster.certificate_authority[0].data
    AWS_DEFAULT_REGION = var.aws_region
  }))

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-lt"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────
# Auto Scaling Group
# ─────────────────────────────────────────────
resource "aws_autoscaling_group" "nodes_asg" {
  name                = "${var.project_name}-${var.environment}-nodes-asg"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  # FIXED: was var.public_subnet_ids.
  # Worker nodes must run in private subnets — nodes in public subnets
  # are directly reachable from the internet. Private subnets route
  # outbound traffic via the NAT Gateway in the VPC module.

  launch_template {
    id      = aws_launch_template.nodes_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.cluster.name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  depends_on = [
    time_sleep.wait_for_cluster,
    aws_eks_addon.vpc_cni
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────
# Security Groups
# ─────────────────────────────────────────────

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.project_name}-${var.environment}-cluster-sg"
  vpc_id      = var.vpc_id
  description = "EKS control plane security group"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "eks_worker_sg" {
  name        = "${var.project_name}-${var.environment}-worker-sg"
  vpc_id      = var.vpc_id
  description = "EKS worker node security group"

  tags = {
    Name        = "${var.project_name}-${var.environment}-worker-sg"
    Environment = var.environment
  }
}

# Cluster → Worker: HTTPS (used by API server to reach kubelet)
resource "aws_security_group_rule" "cluster_to_worker_https" {
  description              = "API server to kubelet HTTPS"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

# Cluster → Worker: kubelet port (kubectl exec, kubectl logs, metrics)
resource "aws_security_group_rule" "cluster_to_worker_kubelet" {
  description              = "API server to kubelet port"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  # ADDED: missing from your original.
  # Port 10250 is required for kubectl exec, kubectl logs, and metrics-server.
  # Without it those commands hang or fail silently.
}

# Worker → Worker: pod-to-pod communication across nodes
resource "aws_security_group_rule" "worker_to_worker" {
  description              = "Pod to pod across nodes"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
  # ADDED: missing from your original.
  # Pods on different nodes communicate via the VPC CNI overlay.
  # Without this rule, any cross-node pod communication fails — services
  # become unreachable as soon as their pods land on different nodes.
}

# Worker → Cluster: node registration and ongoing API calls
resource "aws_security_group_rule" "worker_to_cluster_https" {
  description              = "Node to API server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
}

# Worker egress: reach ECR, S3, AWS APIs via NAT Gateway
resource "aws_security_group_rule" "worker_egress" {
  description       = "Worker all outbound"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_worker_sg.id
}