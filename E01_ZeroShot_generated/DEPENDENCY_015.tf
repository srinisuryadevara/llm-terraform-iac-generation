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

variable "db_instance_identifier" {
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  sensitive   = true
}

variable "db_engine" {
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

variable "db_subnet_group_name" {
  type        = string
  sensitive   = true
}

variable "db_subnet_group_description" {
  type        = string
  sensitive   = true
}

variable "availability_zone" {
  type        = string
  sensitive   = true
}

variable "cidr_block" {
  type        = string
  sensitive   = true
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = var.availability_zone
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.cidr_block, 1, 1)
  availability_zone = "${var.availability_zone}b"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.db_subnet_group_name
  description = var.db_subnet_group_description
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
}

resource "aws_db_instance" "db_instance" {
  identifier           = var.db_instance_identifier
  instance_class       = var.db_instance_class
  engine               = var.db_engine
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}

resource "aws_security_group" "db_security_group" {
  name        = "db_security_group"
  description = "Security group for db instance"
  vpc_id      = var.vpc_id

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
}