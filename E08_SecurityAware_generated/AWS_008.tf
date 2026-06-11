provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR Block"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR Blocks"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR Blocks"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR Block"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-vpc"
    Environment = "prod"
    Project     = var.project
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name        = "${var.project}-igw"
    Environment = "prod"
    Project     = var.project
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = "${var.region}${count.index % 3 + 1}"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.project}-public-subnet-${count.index + 1}"
    Environment = "prod"
    Project     = var.project
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.region}${count.index % 3 + 1}"
  tags = {
    Name        = "${var.project}-private-subnet-${count.index + 1}"
    Environment = "prod"
    Project     = var.project
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name        = "${var.project}-public-rt"
    Environment = "prod"
    Project     = var.project
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id
  tags = {
    Name        = "${var.project}-private-rt-${count.index + 1}"
    Environment = "prod"
    Project     = var.project
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "ssh" {
  name        = "${var.project}-ssh-sg"
  description = "Allow SSH from specific CIDR block"
  vpc_id      = aws_vpc.this.id
  tags = {
    Name        = "${var.project}-ssh-sg"
    Environment = "prod"
    Project     = var.project
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "outbound" {
  name        = "${var.project}-outbound-sg"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.this.id
  tags = {
    Name        = "${var.project}-outbound-sg"
    Environment = "prod"
    Project     = var.project
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}