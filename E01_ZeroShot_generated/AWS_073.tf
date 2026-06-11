provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "public_subnet_id" {
  type        = string
  sensitive   = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id    = var.public_subnet_id

  tags = {
    Name = "NAT-Gateway"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gateway.id
}

output "nat_gateway_public_ip" {
  value = aws_eip.nat_eip.public_ip
}