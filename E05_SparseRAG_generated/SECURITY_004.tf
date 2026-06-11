resource "aws_security_group" "https_sg" {
  name        = "${var.sys_name}-https-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = aws_vpc.sys_vpc.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_https_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.sys_name}-https-sg"
  }
}

variable "sys_name" {
  type        = string
  description = "System name"
}

variable "sys_vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "allowed_https_cidr" {
  type        = list(string)
  description = "Allowed HTTPS CIDR blocks"
}

resource "aws_vpc" "sys_vpc" {
  cidr_block           = var.sys_vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.sys_name}-vpc"
  }
}