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

variable "engine" {
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  type        = string
  default     = "14.3"
}

variable "username" {
  type        = string
  sensitive   = true
}

variable "password" {
  type        = string
  sensitive   = true
}

variable "db_name" {
  type        = string
  default     = "mydb"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

resource "aws_subnet" "db_subnet_1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = var.vpc_id
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "db-subnet-1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = var.vpc_id
  availability_zone = var.availability_zones[1]
  tags = {
    Name = "db-subnet-2"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage    = 20
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.db_instance_class
  name                 = var.db_name
  username             = var.username
  password             = var.password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot  = true
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
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

  tags = {
    Name = "db-sg"
  }
}