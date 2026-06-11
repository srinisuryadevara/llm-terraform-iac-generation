provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "ami_id" {
  type        = string
  sensitive   = true
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  type        = string
  sensitive   = true
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [var.security_group_id]
  subnet_id = var.subnet_id
  key_name               = "example-key"
  tags = {
    Name = "example-ec2-instance"
  }
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Allow inbound traffic on port 22"
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

  tags = {
    Name = "example-security-group"
  }
}