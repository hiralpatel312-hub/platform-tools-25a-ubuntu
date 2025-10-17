resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-${var.environment}-igw" }
}

# Create 3 public subnets
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.this.id
  availability_zone       = element(var.azs, count.index)
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-${var.environment}-public-${count.index+1}" }
}

# Create 3 private subnets
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.azs, count.index)
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 3)
  map_public_ip_on_launch = false
  tags = { Name = "${var.project_name}-${var.environment}-private-${count.index+1}" }
}

# Public route table and route to IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project_name}-${var.environment}-public-rt" }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Minimal SG for EKS control plane & workers (tweak CIDRs as needed)
resource "aws_security_group" "eks_worker_sg" {
  name        = "${var.project_name}-${var.environment}-eks-workers-sg"
  description = "EKS worker nodes SG"
  vpc_id      = aws_vpc.this.id

  # allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow kubelet/ephemeral comms internally and API server
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_worker_sg.id]
    description     = "internal node communication"
  }

  tags = { Name = "${var.project_name}-${var.environment}-eks-workers-sg" }
}
