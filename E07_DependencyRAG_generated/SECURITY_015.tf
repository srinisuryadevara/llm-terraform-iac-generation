variable "vpc_id" {
  type = string
}

variable "https_cidr_blocks" {
  type = list(string)
}

variable "egress_cidr_blocks" {
  type = list(string)
}

resource "aws_security_group" "https_security_group" {
  name        = "HTTPS Security Group"
  description = "Allow HTTPS inbound, block SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.https_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_cidr_blocks
  }

  tags = {
    Name = "HTTPS Security Group"
  }
}