########################
# VPC
########################

resource "aws_vpc" "this" {

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

########################
# Internet Gateway
########################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

########################
# Public Subnets
########################

resource "aws_subnet" "public" {

  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index+1}"
  }
}

########################
# Private App Subnets
########################

resource "aws_subnet" "private_app" {

  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-app-${count.index+1}"
  }
}

########################
# Private DB Subnets
########################

resource "aws_subnet" "private_db" {

  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-db-${count.index+1}"
  }
}

########################
# Elastic IP
########################

resource "aws_eip" "nat" {

  domain = "vpc"

  depends_on = [
    aws_internet_gateway.igw
  ]
}

########################
# NAT Gateway
########################

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat.id

  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

########################
# Public Route Table
########################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.this.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

########################
# Private Route Table
########################

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.this.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

########################
# Public Association
########################

resource "aws_route_table_association" "public" {

  count = 2

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}

########################
# Private App Association
########################

resource "aws_route_table_association" "private_app" {

  count = 2

  subnet_id = aws_subnet.private_app[count.index].id

  route_table_id = aws_route_table.private.id
}

########################
# Private DB Association
########################

resource "aws_route_table_association" "private_db" {

  count = 2

  subnet_id = aws_subnet.private_db[count.index].id

  route_table_id = aws_route_table.private.id
}
