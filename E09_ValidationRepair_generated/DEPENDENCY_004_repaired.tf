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
  default     = "db.t2.micro"
}

variable "db_instance_identifier" {
  type        = string
  default     = "my-rds-instance"
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
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  default     = "14.3"
}

variable "db_port" {
  type        = number
  default     = 5432
}

variable "db_subnet_group_name" {
  type        = string
  default     = "my-rds-subnet-group"
}

variable "db_subnet_group_description" {
  type        = string
  default     = "My RDS subnet group"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name        = "db-subnet-1"
    Environment = "dev"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name        = "db-subnet-2"
    Environment = "dev"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = var.db_subnet_group_name
  description = var.db_subnet_group_description
  subnet_ids  = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]

  tags = {
    Name        = "db-subnet-group"
    Environment = "dev"
  }
}

resource "aws_db_instance" "db_instance" {
  identifier           = var.db_instance_identifier
  instance_class       = var.db_instance_class
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  port                 = var.db_port
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  publicly_accessible  = false

  tags = {
    Name        = "db-instance"
    Environment = "dev"
  }
}

resource "aws_security_group" "db_security_group" {
  name        = "my-rds-security-group"
  description = "My RDS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "db-security-group"
    Environment = "dev"
  }
}

output "db_instance_id" {
  value       = aws_db_instance.db_instance.id
  description = "The ID of the RDS instance"
}

output "db_instance_endpoint" {
  value       = aws_db_instance.db_instance.endpoint
  description = "The endpoint of the RDS instance"
}

output "db_instance_arn" {
  value       = aws_db_instance.db_instance.arn
  description = "The ARN of the RDS instance"
}

output "db_security_group_id" {
  value       = aws_security_group.db_security_group.id
  description = "The ID of the security group"
}

output "db_subnet_group_id" {
  value       = aws_db_subnet_group.db_subnet_group.id
  description = "The ID of the DB subnet group"
}