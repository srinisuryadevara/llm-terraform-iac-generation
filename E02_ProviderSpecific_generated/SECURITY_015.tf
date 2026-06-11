provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "allowed_cidr" {
  type        = list(string)
  sensitive   = true
}

resource "aws_security_group" "https_only" {
  name        = "https_only"
  description = "Allow HTTPS inbound, block SSH"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "https_only"
  }
}