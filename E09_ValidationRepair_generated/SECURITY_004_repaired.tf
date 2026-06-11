variable "allowed_cidr" {
  type        = list(string)
  description = "List of allowed CIDR blocks"
}

variable "denied_cidr" {
  type        = list(string)
  description = "List of denied CIDR blocks"
}

resource "aws_security_group" "https_only" {
  name        = "https_only"
  description = "Security group allowing only HTTPS inbound traffic"
  vpc_id      = "your_vpc_id" # replace with your VPC ID

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
    cidr_blocks = ["10.0.0.0/16"] # restrict to internal network
  }

  tags = {
    Name        = "https_only"
    Environment = "production"
    Owner       = "your_name"
  }
}

resource "aws_security_group_rule" "deny_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/32"] # restrict to internal network
  security_group_id = aws_security_group.https_only.id
}

output "security_group_id" {
  value       = aws_security_group.https_only.id
  description = "The ID of the security group"
}

output "security_group_arn" {
  value       = aws_security_group.https_only.arn
  description = "The ARN of the security group"
}

output "security_group_name" {
  value       = aws_security_group.https_only.name
  description = "The name of the security group"
}