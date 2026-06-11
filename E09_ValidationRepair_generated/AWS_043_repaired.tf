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
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  type        = string
  sensitive   = true
}

variable "security_group_name" {
  type        = string
  sensitive   = true
}

variable "security_group_description" {
  type        = string
  sensitive   = true
}

variable "allowed_ip" {
  type        = string
  sensitive   = true
}

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip + "/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
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

output "instance_id" {
  value       = aws_instance.example.id
  description = "ID of the EC2 instance"
}

output "instance_arn" {
  value       = aws_instance.example.arn
  description = "ARN of the EC2 instance"
}

output "security_group_id" {
  value       = aws_security_group.example.id
  description = "ID of the security group"
}

output "security_group_arn" {
  value       = aws_security_group.example.arn
  description = "ARN of the security group"
}