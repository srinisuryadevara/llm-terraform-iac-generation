provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "db_instance_class" {
  type        = string
  description = "DB Instance Class"
}

variable "db_instance_identifier" {
  type        = string
  description = "DB Instance Identifier"
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

variable "db_subnet_group_name" {
  type        = string
  description = "DB Subnet Group Name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs"
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "db-subnet-1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "db-subnet-2"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.db_subnet_group_name
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
  tags = {
    Name = var.db_subnet_group_name
  }
}

resource "aws_db_instance" "db_instance" {
  instance_class        = var.db_instance_class
  identifier            = var.db_instance_identifier
  username              = var.db_username
  password              = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  engine               = "postgres"
  engine_version       = "14.1"
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  tags = {
    Name = var.db_instance_identifier
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security Group for DB"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "db-sg"
  }
}