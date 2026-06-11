terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "hashicat" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc-${var.region}"
  }
}

resource "aws_subnet" "hashicat_1" {
  vpc_id     = aws_vpc.hashicat.id
  cidr_block = var.subnet_prefix_1
  availability_zone = var.availability_zone_1

  tags = {
    name = "${var.prefix}-subnet-1"
  }
}

resource "aws_subnet" "hashicat_2" {
  vpc_id     = aws_vpc.hashicat.id
  cidr_block = var.subnet_prefix_2
  availability_zone = var.availability_zone_2

  tags = {
    name = "${var.prefix}-subnet-2"
  }
}

resource "aws_db_subnet_group" "default" {
  subnet_ids = [aws_subnet.hashicat_1.id, aws_subnet.hashicat_2.id]

  tags {
    Name               = "GrayMetaPlatform-${var.platform_instance_id}-RDS"
    ApplicationName    = "GrayMetaPlatform"
    PlatformInstanceID = "${var.platform_instance_id}"
  }
}

resource "aws_security_group" "hashicat" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.hashicat.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-security-group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = var.parameter_group_name
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.hashicat.id]
  skip_final_snapshot  = true
}

resource "aws_instance" "hashicat" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.hashicat_1.id
  vpc_security_group_ids = [aws_security_group.hashicat.id]
  key_name               = var.key_name

  tags = {
    Name = "${var.prefix}-instance"
  }
}