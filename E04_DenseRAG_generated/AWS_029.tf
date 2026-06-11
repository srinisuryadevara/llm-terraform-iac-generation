variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t2.micro"
  description = "RDS Instance Class"
}

variable "rds_engine_version" {
  type        = string
  default     = "8.0.20"
  description = "RDS Engine Version"
}

variable "rds_username" {
  type        = string
  sensitive   = true
  description = "RDS Username"
}

variable "rds_password" {
  type        = string
  sensitive   = true
  description = "RDS Password"
}

variable "rds_database_name" {
  type        = string
  default     = "mydb"
  description = "RDS Database Name"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "rds" {
  name   = "mysql-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "mysql-rds-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name = "mysql-rds-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage               = 30
  storage_type                    = "gp2"
  engine                          = "mysql"
  engine_version                  = var.rds_engine_version
  instance_class                  = var.rds_instance_class
  name                            = var.rds_database_name
  username                        = var.rds_username
  password                        = var.rds_password
  multi_az                        = false
  port                            = 3306
  db_subnet_group_name            = aws_db_subnet_group.rds.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  tags                            = {
    Name = "mysql-rds-instance"
  }
}