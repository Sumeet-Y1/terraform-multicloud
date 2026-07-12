terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# ---------- PUBLIC SUBNETS ----------
resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = "${var.aws_region}${each.key}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-${each.key}"
    Environment = var.environment
    Tier        = "public"
  }
}

# ---------- PRIVATE (APP) SUBNETS ----------
resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "${var.aws_region}${each.key}"

  tags = {
    Name        = "${var.environment}-private-${each.key}"
    Environment = var.environment
    Tier        = "private"
  }
}

# ---------- DATABASE SUBNETS ----------
resource "aws_subnet" "database" {
  for_each          = var.database_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "${var.aws_region}${each.key}"

  tags = {
    Name        = "${var.environment}-database-${each.key}"
    Environment = var.environment
    Tier        = "database"
  }
}

# ---------- NAT GATEWAY (for private subnet outbound internet) ----------
# One Elastic IP per NAT Gateway
resource "aws_eip" "nat" {
  for_each = var.public_subnets
  domain   = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip-${each.key}"
    Environment = var.environment
  }
}

# NAT Gateway sits in a public subnet, serves the private subnet in the same AZ
resource "aws_nat_gateway" "main" {
  for_each      = var.public_subnets
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name        = "${var.environment}-nat-${each.key}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# ---------- ROUTE TABLES ----------

# Public route table (single, shared by all public subnets)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route tables — one per AZ, each routing through its own NAT Gateway
resource "aws_route_table" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }

  tags = {
    Name        = "${var.environment}-private-rt-${each.key}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Database subnets — no internet route at all (fully isolated tier)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-database-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "database" {
  for_each       = aws_subnet.database
  subnet_id      = each.value.id
  route_table_id = aws_route_table.database.id
}

# ---------- SECURITY GROUPS ----------

# Web tier — allows HTTP/HTTPS from anywhere
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
  }
}

# App tier — only allows traffic from the web tier SG
resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Allow traffic only from web tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From web SG"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-app-sg"
    Environment = var.environment
  }
}

# Database tier — only allows traffic from the app tier SG
resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Allow traffic only from app tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From app SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-database-sg"
    Environment = var.environment
  }
}