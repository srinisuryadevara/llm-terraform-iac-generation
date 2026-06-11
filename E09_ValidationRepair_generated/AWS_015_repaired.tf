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
  value       = aws_eip.this.id
  description = "The Allocation ID of the EIP"
}

output "nat_gateway_arn" {
  value       = aws_nat_gateway.this.arn
  description = "The ARN of the NAT Gateway"
}