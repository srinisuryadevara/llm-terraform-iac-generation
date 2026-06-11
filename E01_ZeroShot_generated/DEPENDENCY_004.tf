provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  sensitive   = true
}

variable "db_instance_identifier" {
  type        = string
  sensitive   = true
}

variable "db_username" {
  type        = string
  sensitive   = true
}

variable "db_password" {
  type        = string
  sensitive   = true
}

variable "db_engine" {
  type        = string
  sensitive   = true
}

variable "db_engine_version" {
  type        = string
  sensitive   = true
}

variable "db_port" {
  type        = number
  sensitive   = true
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
}

resource "aws_db_instance" "db_instance" {
  identifier           = var.db_instance_identifier
  instance_class        = var.db_instance_class
  engine                = var.db_engine
  engine_version         = var.db_engine_version
  port                  = var.db_port
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name  = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  skip_final_snapshot    = true
}

resource "aws_security_group" "db_security_group" {
  name        = "db-security-group"
  description = "Security group for DB instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}