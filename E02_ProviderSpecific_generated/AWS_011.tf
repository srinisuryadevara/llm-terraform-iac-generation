variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

provider "aws" {
  region = var.region
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "NAT Gateway"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true
}