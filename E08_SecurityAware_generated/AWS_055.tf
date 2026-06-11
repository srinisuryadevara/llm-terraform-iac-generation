provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "key_name" {
  type        = string
  description = "SSH Key Name"
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "EC2 Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ec2-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]
  key_name               = var.key_name

  tags = {
    Name        = "ec2-instance"
    Project     = var.project
    Environment = var.environment
  }
}