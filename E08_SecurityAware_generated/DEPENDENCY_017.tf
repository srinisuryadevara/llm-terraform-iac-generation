provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH allowed CIDR"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "key_name" {
  type        = string
  description = "SSH key name"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "example-vpc"
    Environment = "example"
  }
}

resource "aws_subnet" "this" {
  cidr_block = var.subnet_cidr
  vpc_id     = aws_vpc.this.id
  availability_zone = "us-west-2a"
  tags = {
    Name        = "example-subnet"
    Environment = "example"
  }
}

resource "aws_security_group" "this" {
  name        = "example-sg"
  description = "Allow SSH from specific CIDR"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from specific CIDR"
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
    Name        = "example-sg"
    Environment = "example"
  }
}

resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.this.id
  vpc_security_group_ids = [aws_security_group.this.id]
  key_name               = var.key_name

  tags = {
    Name        = "example-ec2"
    Environment = "example"
  }
}