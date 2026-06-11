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

resource "aws_eip" "this" {
  vpc = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "NAT-Gateway"
  }
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.this.id
  description = "The ID of the NAT Gateway"
}

output "eip_allocation_id" {
  value       = aws_eip.this.allocation_id
  description = "The Allocation ID of the Elastic IP"
}

output "eip_public_ip" {
  value       = aws_eip.this.public_ip
  description = "The Public IP of the Elastic IP"
}