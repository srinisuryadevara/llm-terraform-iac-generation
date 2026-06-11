variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_id" {
  type        = string
  description = "Public Subnet ID"
}

variable "nat_gateway_allocation_id" {
  type        = string
  description = "NAT Gateway Allocation ID"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_nat_gateway" "this" {
  allocation_id = var.nat_gateway_allocation_id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "nat-gateway"
  }
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.this.id
  description = "NAT Gateway ID"
}

output "nat_gateway_public_ip" {
  value       = aws_nat_gateway.this.public_ip
  description = "NAT Gateway Public IP"
}