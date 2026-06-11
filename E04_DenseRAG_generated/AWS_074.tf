variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "private_subnet_id" {
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "rds_engine_version" {
  type        = string
  default     = "8.0.20"
}

variable "rds_username" {
  type        = string
  sensitive   = true
}

variable "rds_password" {
  type        = string
  sensitive   = true
}

variable "rds_database_name" {
  type        = string
  default     = "mydb"
}

variable "rds_port" {
  type        = number
  default     = 3306
}

variable "rds_allocated_storage" {
  type        = number
  default     = 30
}

variable "rds_storage_type" {
  type        = string
  default     = "gp2"
}

variable "rds_multi_az" {
  type        = bool
  default     = true
}

resource "aws_security_group" "rds" {
  name        = "internal-mysql"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.rds_port
    to_port   = var.rds_port
    protocol  = "tcp"
    self      = true
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
  allocated_storage               = var.rds_allocated_storage
  storage_type                    = var.rds_storage_type
  engine                          = "mysql"
  engine_version                  = var.rds_engine_version
  instance_class                  = var.rds_instance_class
  name                            = var.rds_database_name
  username                        = var.rds_username
  password                        = var.rds_password
  multi_az                        = var.rds_multi_az
  port                            = var.rds_port
  db_subnet_group_name            = aws_db_subnet_group.rds.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  tags                            = {
    Name = "RDS MySQL"
  }
}