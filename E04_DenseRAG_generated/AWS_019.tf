variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "db_port" {
  type = number
}

resource "aws_security_group" "rds" {
  name   = "mysql-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = var.db_port
    to_port   = var.db_port
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
    Name = "mysql-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "mysql-rds-subnet-group"
  subnet_ids = [var.private_subnet_id]

  tags = {
    Name = "mysql-rds-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage               = 30
  storage_type                    = "gp2"
  engine                          = "mysql"
  engine_version                  = var.db_engine_version
  instance_class                  = var.db_instance_class
  name                            = var.db_name
  username                        = var.db_username
  password                        = var.db_password
  port                            = var.db_port
  db_subnet_group_name            = aws_db_subnet_group.rds.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  multi_az                        = false
  publicly_accessible             = false
  deletion_protection              = false
  skip_final_snapshot              = true

  tags = {
    Name = "mysql-rds-instance"
  }
}