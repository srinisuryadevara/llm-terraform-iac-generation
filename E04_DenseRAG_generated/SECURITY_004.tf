terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.aws_region
  profile = "default"
}

resource "aws_security_group" "https_security_group" {
  name        = "HTTPS Security Group"
  description = "Security group to allow inbound HTTPS connections"

  ingress {
    description = "Inbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
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

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR for HTTPS access"
}