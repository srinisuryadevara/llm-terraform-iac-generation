variable "allowed_cidr_blocks" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

resource "aws_security_group" "https_only" {
  name        = "https_only"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] # restrict to private IP ranges
  }

  tags = {
    Name = "https_only"
  }
}

output "security_group_id" {
  value = aws_security_group.https_only.id
}

output "security_group_arn" {
  value = aws_security_group.https_only.arn
}