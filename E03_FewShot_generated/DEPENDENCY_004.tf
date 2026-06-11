variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS secret key"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "db_instance_class" {
  type        = string
  description = "DB instance class"
}

variable "db_instance_identifier" {
  type        = string
  description = "DB instance identifier"
}

variable "db_engine" {
  type        = string
  description = "DB engine"
}

variable "db_engine_version" {
  type        = string
  description = "DB engine version"
}

variable "db_username" {
  type        = string
  sensitive   = true
  description = "DB username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "DB password"
}

variable "db_subnet_group_name" {
  type        = string
  description = "DB subnet group name"
}

variable "db_subnet_group_description" {
  type        = string
  description = "DB subnet group description"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = var.db_subnet_group_name
  description = var.db_subnet_group_description
  subnet_ids  = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
}

resource "aws_db_instance" "db_instance" {
  instance_class         = var.db_instance_class
  identifier             = var.db_instance_identifier
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = []
  publicly_accessible    = false
  skip_final_snapshot    = true
}