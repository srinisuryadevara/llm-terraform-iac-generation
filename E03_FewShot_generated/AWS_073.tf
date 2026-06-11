provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Public Subnet ID"
}

variable "nat_gateway_tags" {
  type        = map(string)
  description = "NAT Gateway Tags"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = var.subnet_id
  tags          = var.nat_gateway_tags
}

resource "aws_eip" "this" {
  vpc = true
}