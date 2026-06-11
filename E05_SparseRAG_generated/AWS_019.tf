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

variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
}

#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

#--------------------------------------------------------------
# Internet Gateway
#--------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#--------------------------------------------------------------
# Private subnet
#--------------------------------------------------------------

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "private-rtb-assoc" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rtb.id
}

#--------------------------------------------------------------
# RDS Security group
#--------------------------------------------------------------

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow MySQL access from private subnet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#--------------------------------------------------------------
# RDS MySQL instance
#--------------------------------------------------------------

resource "aws_db_instance" "mysql_instance" {
  instance_class = var.db_instance_class
  engine         = "mysql"
  engine_version = "8.0.23"
  username       = var.db_username
  password       = var.db_password
  db_name        = var.db_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.mysql_subnet_group.name
  skip_final_snapshot     = true
}

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql_subnet_group"
  subnet_ids = [aws_subnet.private-subnet.id]
}

output "rds_instance_id" {
  value = aws_db_instance.mysql_instance.id
}

output "rds_instance_endpoint" {
  value = aws_db_instance.mysql_instance.endpoint
}