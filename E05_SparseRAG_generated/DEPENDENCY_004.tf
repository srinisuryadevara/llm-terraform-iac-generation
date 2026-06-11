provider "aws" {
  region  = var.region
  profile = var.profile
}

terraform {
  backend "s3" {
    bucket  = var.state_bucket
    key     = var.state_key
    region  = var.region
    profile = var.profile
  }
}

variable "region" {
  type = string
}

variable "profile" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "state_key" {
  type = string
}

variable "sys_name" {
  type = string
}

variable "data_db_name" {
  type = string
}

variable "data_master_db_password" {
  type      = string
  sensitive = true
}

variable "vpc_cidr_block" {
  type = string
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.sys_name}-vpc"
  }
}

#--------------------------------------------------------------
# Internet Gateway
#--------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.sys_name}-igw"
  }
}

#--------------------------------------------------------------
# Public subnets
#--------------------------------------------------------------

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.sys_name}-public-subnet-${count.index + 1}"
  }
}

#--------------------------------------------------------------
# Private subnets
#--------------------------------------------------------------

resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.sys_name}-private-subnet-${count.index + 1}"
  }
}

#--------------------------------------------------------------
# Public route table
#--------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.sys_name}-public-rtb"
  }
}

#--------------------------------------------------------------
# Private route table
#--------------------------------------------------------------

resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.sys_name}-private-rtb"
  }
}

#--------------------------------------------------------------
# Route table associations
#--------------------------------------------------------------

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private_subnets)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_default_route_table.private.id
}

#--------------------------------------------------------------
# Security group for RDS
#--------------------------------------------------------------

resource "aws_security_group" "rds_sg" {
  name        = "${var.sys_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
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
    Name = "${var.sys_name}-rds-sg"
  }
}

#--------------------------------------------------------------
# DB subnet group
#--------------------------------------------------------------

resource "aws_db_subnet_group" "db_subnet_grp" {
  name       = "${var.sys_name}-db-subnet-grp"
  subnet_ids = [for s in aws_subnet.private_subnets : s.id]

  tags = {
    Name = "${var.sys_name}-db-subnet-grp"
  }
}

#--------------------------------------------------------------
# RDS instance
#--------------------------------------------------------------

resource "aws_db_instance" "rds_instance" {
  identifier            = "${var.sys_name}-rds-instance"
  db_name               = var.data_db_name
  engine                = "postgres"
  engine_version        = "12.11"
  instance_class        = "db.t3.medium"
  allocated_storage     = 29
  max_allocated_storage = 1000
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
  parameter_group_name = "default.postgres12"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_grp.name
  username             = "postgres"
  password             = var.data_master_db_password
  apply_immediately    = true
}

#--------------------------------------------------------------
# IAM role for RDS monitoring
#--------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.sys_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
}