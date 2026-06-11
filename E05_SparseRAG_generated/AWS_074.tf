provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  backend "s3" {
    bucket  = var.tf_state_bucket
    key     = var.tf_state_key
    region  = var.aws_region
    profile = var.aws_profile
  }
}

#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

#--------------------------------------------------------------
# Internet Gateway
#--------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.igw_name
  }
}

#--------------------------------------------------------------
# Public subnet
#--------------------------------------------------------------
resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_subnet_name
  }
}

#--------------------------------------------------------------
# Private subnet
#--------------------------------------------------------------
resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.private_subnet_az
  map_public_ip_on_launch = false
  tags = {
    Name = var.private_subnet_name
  }
}

#--------------------------------------------------------------
# Route table for public subnet
#--------------------------------------------------------------
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = var.public_rt_name
  }
}

#--------------------------------------------------------------
# Route table association for public subnet
#--------------------------------------------------------------
resource "aws_route_table_association" "public-rtb-assoc" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rtb.id
}

#--------------------------------------------------------------
# Route table for private subnet
#--------------------------------------------------------------
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.private_rt_name
  }
}

#--------------------------------------------------------------
# Route table association for private subnet
#--------------------------------------------------------------
resource "aws_route_table_association" "private-rtb-assoc" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rtb.id
}

#--------------------------------------------------------------
# Security group for RDS
#--------------------------------------------------------------
resource "aws_security_group" "rds-sg" {
  name        = var.rds_sg_name
  description = "Allow RDS access"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      aws_security_group.ec2-sg.id
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.rds_sg_name
  }
}

#--------------------------------------------------------------
# Security group for EC2
#--------------------------------------------------------------
resource "aws_security_group" "ec2-sg" {
  name        = var.ec2_sg_name
  description = "Allow EC2 access"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      var.local_ip
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.ec2_sg_name
  }
}

#--------------------------------------------------------------
# RDS instance
#--------------------------------------------------------------
resource "aws_db_instance" "rds-instance" {
  allocated_storage    = var.rds_allocated_storage
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  name                 = var.rds_name
  username             = var.rds_username
  password             = var.rds_password
  parameter_group_name = var.rds_parameter_group_name
  vpc_security_group_ids = [
    aws_security_group.rds-sg.id
  ]
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  skip_final_snapshot  = true
}

#--------------------------------------------------------------
# RDS subnet group
#--------------------------------------------------------------
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = var.rds_subnet_group_name
  subnet_ids = [
    aws_subnet.private-subnet.id
  ]
  tags = {
    Name = var.rds_subnet_group_name
  }
}

output "rds_instance_id" {
  value = aws_db_instance.rds-instance.id
}

output "rds_instance_endpoint" {
  value = aws_db_instance.rds-instance.endpoint
}

output "rds_instance_status" {
  value = aws_db_instance.rds-instance.status
}

variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "tf_state_bucket" {
  type = string
}

variable "tf_state_key" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "igw_name" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "public_subnet_az" {
  type = string
}

variable "public_subnet_name" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

variable "private_subnet_az" {
  type = string
}

variable "private_subnet_name" {
  type = string
}

variable "public_rt_name" {
  type = string
}

variable "private_rt_name" {
  type = string
}

variable "rds_sg_name" {
  type = string
}

variable "ec2_sg_name" {
  type = string
}

variable "local_ip" {
  type = string
}

variable "rds_allocated_storage" {
  type = number
}

variable "rds_engine" {
  type = string
}

variable "rds_engine_version" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_name" {
  type = string
}

variable "rds_username" {
  type = string
}

variable "rds_password" {
  type = string
}

variable "rds_parameter_group_name" {
  type = string
}

variable "rds_subnet_group_name" {
  type = string
}