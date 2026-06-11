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

variable "subnet_id" {
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "db_instance_identifier" {
  type        = string
  default     = "mysql-rds-instance"
}

variable "db_username" {
  type        = string
  sensitive   = true
}

variable "db_password" {
  type        = string
  sensitive   = true
}

variable "db_name" {
  type        = string
  default     = "mysql_db"
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Security group for MySQL RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "mysql-sg"
  }
}

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name = "mysql-subnet-group"
  }
}

resource "aws_db_instance" "mysql_rds_instance" {
  identifier           = var.db_instance_identifier
  instance_class       = var.db_instance_class
  engine               = "mysql"
  engine_version       = "8.0.28"
  username             = var.db_username
  password             = var.db_password
  db_name              = var.db_name
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name
  publicly_accessible  = false
  skip_final_snapshot  = true
}