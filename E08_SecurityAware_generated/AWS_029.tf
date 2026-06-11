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
  description = "Environment"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "private_subnet_cidr" {
  type        = string
  description = "Private Subnet CIDR"
}

variable "db_instance_class" {
  type        = string
  description = "RDS Instance Class"
}

variable "db_username" {
  type        = string
  description = "RDS Username"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "RDS Password"
  sensitive   = true
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH Source CIDR"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}a"
  tags = {
    Name        = "${var.project}-${var.environment}-private"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      var.private_subnet_cidr,
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-rds"
    Environment = var.environment
  }
}

resource "aws_db_instance" "this" {
  instance_class         = var.db_instance_class
  engine                 = "mysql"
  engine_version         = "8.0.28"
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  storage_type           = "gp2"
  allocated_storage      = 20
  skip_final_snapshot    = true
  deletion_protection    = false
  tags = {
    Name        = "${var.project}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}"
  subnet_ids = [aws_subnet.private.id]
  tags = {
    Name        = "${var.project}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "ssh" {
  name        = "${var.project}-${var.environment}-ssh"
  description = "SSH Security Group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      var.ssh_source_cidr,
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-ssh"
    Environment = var.environment
  }
}