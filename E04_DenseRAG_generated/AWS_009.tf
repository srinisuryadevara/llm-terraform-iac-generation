variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_engine_version" {
  type = string
}

variable "rds_username" {
  type = string
  sensitive = true
}

variable "rds_password" {
  type = string
  sensitive = true
}

variable "rds_db_name" {
  type = string
}

resource "aws_security_group" "rds" {
  name   = "internal-mysql"
  vpc_id = var.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "internal-mysql"
    Environment = "prod"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [var.private_subnet_id]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage               = 30
  storage_type                    = "gp2"
  engine                          = "mysql"
  engine_version                  = var.rds_engine_version
  instance_class                  = var.rds_instance_class
  name                            = var.rds_db_name
  username                        = var.rds_username
  password                        = var.rds_password
  multi_az                        = false
  port                            = 3306
  db_subnet_group_name            = aws_db_subnet_group.rds.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  tags                            = {
    Name = "RDS MySQL"
  }
}