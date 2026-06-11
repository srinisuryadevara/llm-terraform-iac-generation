terraform {
  required_version = "1.3.9"
}

provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "ami_id" {
  type        = string
  description = "ID of AMI to use for the instance"
}

variable "instance_type" {
  type        = string
  description = "Type of instance to start"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC"
}

variable "subnet_id" {
  type        = string
  description = "ID of subnet"
}

variable "security_group_id" {
  type        = string
  description = "ID of security group"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "main" {
  id = var.subnet_id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["canonical"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.example.id
  ]

  tags = {
    Name = "example-ec2-instance"
  }
}