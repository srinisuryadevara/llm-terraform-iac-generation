variable "aws_region" {
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  type        = string
}

variable "subnet_id" {
  type        = string
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "rds_engine_version" {
  type        = string
  default     = "8.0.20"
}

variable "rds_allocated_storage" {
  type        = number
  default     = 30
}

variable "rds_storage_type" {
  type        = string
  default     = "gp2"
}

variable "rds_username" {
  type        = string
  sensitive   = true
}

variable "rds_password" {
  type        = string
  sensitive   = true
}

variable "rds_db_name" {
  type        = string
  default     = "mydb"
}

variable "rds_port" {
  type        = number
  default     = 3306
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS MySQL instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.rds_port
    protocol  = "tcp"
    to_port   = var.rds_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage               = var.rds_allocated_storage
  storage_type                    = var.rds_storage_type
  engine                          = "mysql"
  engine_version                  = var.rds_engine_version
  instance_class                  = var.rds_instance_class
  name                            = var.rds_db_name
  username                        = var.rds_username
  password                        = var.rds_password
  port                            = var.rds_port
  db_subnet_group_name            = aws_db_subnet_group.rds.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  multi_az                        = false
  publicly_accessible             = false
  skip_final_snapshot              = true
}