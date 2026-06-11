provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "rds_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.rds_subnet_1_cidr
  availability_zone = var.rds_subnet_1_az
  tags = {
    Name = var.rds_subnet_1_name
  }
}

resource "aws_subnet" "rds_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.rds_subnet_2_cidr
  availability_zone = var.rds_subnet_2_az
  tags = {
    Name = var.rds_subnet_2_name
  }
}

resource "aws_db_subnet_group" "default" {
  name       = var.db_subnet_group_name
  subnet_ids = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]

  tags = {
    Name               = var.db_subnet_group_name
    ApplicationName    = var.application_name
    Environment        = var.environment
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot  = true
}

resource "aws_security_group" "rds_sg" {
  name        = var.rds_sg_name
  description = var.rds_sg_description
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.rds_port
    to_port     = var.rds_port
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.rds_sg_name
  }
}

variable "region" {
  type        = string
  default     = "us-west-2"
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  type        = string
  default     = "main-vpc"
}

variable "rds_subnet_1_cidr" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "rds_subnet_1_az" {
  type        = string
  default     = "us-west-2a"
}

variable "rds_subnet_1_name" {
  type        = string
  default     = "rds-subnet-1"
}

variable "rds_subnet_2_cidr" {
  type        = string
  default     = "10.0.2.0/24"
}

variable "rds_subnet_2_az" {
  type        = string
  default     = "us-west-2b"
}

variable "rds_subnet_2_name" {
  type        = string
  default     = "rds-subnet-2"
}

variable "db_subnet_group_name" {
  type        = string
  default     = "default-db-subnet-group"
}

variable "allocated_storage" {
  type        = number
  default     = 20
}

variable "engine" {
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  type        = string
  default     = "13.4"
}

variable "instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "db_name" {
  type        = string
  default     = "mydb"
}

variable "db_username" {
  type        = string
  default     = "myuser"
}

variable "db_password" {
  type        = string
  sensitive   = true
}

variable "rds_port" {
  type        = number
  default     = 5432
}

variable "rds_sg_name" {
  type        = string
  default     = "rds-sg"
}

variable "rds_sg_description" {
  type        = string
  default     = "Security group for RDS instance"
}

variable "application_name" {
  type        = string
  default     = "my-application"
}

variable "environment" {
  type        = string
  default     = "dev"
}