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

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "DB Subnet CIDRs"
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
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "DB Password"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_subnet" "db" {
  count = length(var.db_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = "${var.region}${count.index % 3 + 1}"
  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-${count.index + 1}"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.db.*.id
  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "DB Security Group"
  vpc_id      = aws_vpc.this.id
  tags = {
    Name        = "${var.project}-${var.environment}-db-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "db_ingress" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = [var.ssh_cidr]
  security_group_id = aws_security_group.db.id
}

resource "aws_db_instance" "this" {
  identifier           = "${var.project}-${var.environment}-db"
  instance_class       = var.db_instance_class
  engine               = var.db_engine
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  storage_type         = "gp2"
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.this.arn
  tags = {
    Name        = "${var.project}-${var.environment}-db"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_key" "this" {
  description             = "${var.project}-${var.environment}-db-kms-key"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.project}-${var.environment}-db-kms-key"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project}-${var.environment}-db-kms-key"
  target_key_id = aws_kms_key.this.key_id
}