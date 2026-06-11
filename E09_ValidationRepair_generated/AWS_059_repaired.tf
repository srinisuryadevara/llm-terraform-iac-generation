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

variable "security_group_id" {
  type        = string
  sensitive   = true
}

variable "key_name" {
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [
    aws_security_group.example.id
  ]
  key_name               = var.key_name

  tags = {
    Name        = "example-ec2"
    Environment = "example"
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound traffic on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "Allow inbound traffic on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
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