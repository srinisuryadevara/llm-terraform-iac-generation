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

variable "environment" {
  type        = string
  description = "Environment Name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "db_instance_class" {
  type        = string
  description = "DB Instance Class"
}

variable "db_engine" {
  type        = string
  description = "DB Engine"
}

variable "db_username" {
  type        = string
  description = "DB Username"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "DB Password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "DB Name"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_subnet" "this" {
  count = length(var.subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = "${var.region}${count.index % 3 + 1}"
  tags = {
    Name        = "${var.project}-${var.environment}-subnet-${count.index + 1}"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.this.*.id
  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_db_instance" "this" {
  instance_class    = var.db_instance_class
  engine            = var.db_engine
  username          = var.db_username
  password          = var.db_password
  db_name           = var.db_name
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  storage_encryption = true
  tags = {
    Name        = "${var.project}-${var.environment}-db-instance"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "DB Security Group"
  vpc_id      = aws_vpc.this.id
  tags = {
    Name        = "${var.project}-${var.environment}-db-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "this" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "Allowed CIDRs for DB access"
}