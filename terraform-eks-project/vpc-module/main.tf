resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr

  tags = {
    Name = local.vpc_name
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = local.subnet_a_cidr

  tags = {
    Name = local.subnet_a_tag
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = local.subnet_b_cidr


  tags = {
    Name = local.subnet_b_tag
  }
}

output "subnet_ids" {
  value = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.ig_tag
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = local.route_table_tag
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}
