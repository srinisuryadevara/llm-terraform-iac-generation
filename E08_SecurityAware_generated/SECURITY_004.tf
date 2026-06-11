variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC"
}

variable "allowed_https_cidr" {
  type        = string
  description = "The CIDR block allowed to access HTTPS"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy to"
}

variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "environment" {
  type        = string
  description = "The environment to deploy to"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "https_only" {
  name        = "${var.project_name}-${var.environment}-https-only-sg"
  description = "Security group allowing only HTTPS inbound"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_https_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-https-only-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}