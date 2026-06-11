provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = var.subnet_id

  tags = {
    Name = "NAT-Gateway"
  }
}

resource "aws_eip" "this" {
  vpc = true
}