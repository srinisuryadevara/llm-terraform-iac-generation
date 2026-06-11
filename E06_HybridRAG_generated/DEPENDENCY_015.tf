variable "sys_name" {
  type = string
}

variable "data_db_name" {
  type = string
}

variable "data_master_db_password" {
  type      = string
  sensitive = true
}

variable "platform_instance_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "cidr_blocks" {
  type = list(string)
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidr_blocks[count.index]
  availability_zone = availability_zones[count.index]

  tags = {
    Name = "${var.sys_name}-private-subnet-${count.index}"
  }
}

resource "aws_db_subnet_group" "data_db_subnet_grp" {
  name = "${var.sys_name}-db-subnet-grp"
  subnet_ids = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id
  ]

  tags = {
    Name               = "${var.sys_name}-db-subnet-grp"
    ApplicationName    = "GrayMetaPlatform"
    PlatformInstanceID = var.platform_instance_id
  }
}

resource "aws_security_group" "data_db_sg" {
  name        = "${var.sys_name}-data-db-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.this.id

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
    Name = "${var.sys_name}-data-db-sg"
  }
}

resource "aws_db_instance" "data_dbi" {
  identifier            = "${var.sys_name}-data-dbi"
  db_name               = var.data_db_name
  engine                = "postgres"
  engine_version        = "12.11"
  instance_class        = "db.t3.medium"
  allocated_storage     = 29
  max_allocated_storage = 1000
  vpc_security_group_ids = [
    aws_security_group.data_db_sg.id
  ]
  parameter_group_name                = "default.postgres12"
  db_subnet_group_name                = aws_db_subnet_group.data_db_subnet_grp.name
  username                            = "postgres"
  password                            = var.data_master_db_password
  apply_immediately                   = true
}