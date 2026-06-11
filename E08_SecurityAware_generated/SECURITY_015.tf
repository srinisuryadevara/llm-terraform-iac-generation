variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "https_cidr" {
  type        = string
  description = "CIDR block for HTTPS access"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

provider "aws" {
  region = var.region
}

resource "aws_security_group" "https_sg" {
  name        = "${var.project}-${var.environment}-https-sg"
  description = "Security group allowing only HTTPS inbound"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow HTTPS from specific CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.https_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-https-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Project     = var.project
    Environment = var.environment
  }
}