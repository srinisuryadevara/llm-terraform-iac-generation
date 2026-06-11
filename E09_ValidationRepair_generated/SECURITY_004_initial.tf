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
}

resource "aws_security_group_rule" "deny_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.denied_cidr
  security_group_id = aws_security_group.https_only.id
}