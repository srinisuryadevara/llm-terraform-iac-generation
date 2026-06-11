variable "https_cidr" {
  type        = string
  description = "CIDR block for HTTPS access"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

resource "aws_security_group" "https_security_group" {
  name        = "HTTPS Security Group"
  description = "Allow HTTPS access on Port 443"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.https_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HTTPS Security Group"
  }
}