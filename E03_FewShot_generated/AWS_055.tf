provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "ami_id" {
  type        = string
  description = "ID of the AMI to use"
}

variable "instance_type" {
  type        = string
  description = "Type of the instance to use"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to place the instance in"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "security_group_name" {
  type        = string
  description = "Name of the security group"
}

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

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
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [
    aws_security_group.example.id
  ]

  tags = {
    Name = "example-ec2-instance"
  }
}