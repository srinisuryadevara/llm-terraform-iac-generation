provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_key" {
  type = string
  sensitive = true
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.main.id
  availability_zone = var.region
  cidr_block = var.public_cidr
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Allow inbound traffic on port 22"
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

  tags = {
    Name = "ec2_sg"
  }
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2_key"
  public_key = var.public_key
}

resource "aws_instance" "ec2_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.ec2_key.key_name

  tags = {
    Name = "ec2_instance"
  }
}