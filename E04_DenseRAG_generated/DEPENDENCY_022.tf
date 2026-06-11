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

variable "security_group_name" {
  type        = string
  description = "Name of security group"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = "Allow inbound traffic on port 22"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.example.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.example.id
  vpc_security_group_ids = [
    aws_security_group.example.id
  ]

  tags = {
    Name = "example-instance"
  }
}