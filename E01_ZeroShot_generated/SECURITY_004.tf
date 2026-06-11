variable "allowed_cidr" {
  type        = list(string)
  description = "List of allowed CIDR blocks"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

resource "aws_security_group" "https_only" {
  name        = "https-only-sg"
  description = "Allow HTTPS inbound, block SSH"
  vpc_id      = var.vpc_id

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
    Name = "https-only-sg"
  }
}