provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "db_instance_identifier" {
  type        = string
  sensitive   = false
}

variable "db_instance_class" {
  type        = string
  sensitive   = false
}

variable "db_engine" {
  type        = string
  sensitive   = false
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
  sensitive   = false
}

variable "vpc_security_group_ids" {
  type        = list(string)
  sensitive   = false
}

resource "aws_db_instance" "this" {
  identifier           = var.db_instance_identifier
  instance_class        = var.db_instance_class
  engine                = var.db_engine
  username              = var.db_username
  password              = var.db_password
  db_subnet_group_name = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  storage_type          = "gp2"
  storage_encrypted     = true
  publicly_accessible   = false
}

output "db_instance_address" {
  value       = aws_db_instance.this.address
  description = "The address of the RDS instance"
}

output "db_instance_arn" {
  value       = aws_db_instance.this.arn
  description = "The ARN of the RDS instance"
}