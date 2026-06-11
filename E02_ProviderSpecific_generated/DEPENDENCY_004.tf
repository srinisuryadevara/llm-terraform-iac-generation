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

resource "aws_subnet" "db_subnet_1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = var.vpc_id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "db_subnet_2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = var.vpc_id
  availability_zone = "us-east-1b"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
}

resource "aws_db_instance" "db_instance" {
  instance_class = var.db_instance_class
  identifier      = var.db_instance_identifier
  engine           = var.db_engine
  username         = var.db_username
  password         = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
}