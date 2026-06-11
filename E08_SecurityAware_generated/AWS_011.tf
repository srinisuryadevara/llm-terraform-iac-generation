provider "aws" {
  region = var.region
}

variable "region" {
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

variable "tags" {
  type        = map(string)
  description = "Tags for NAT Gateway"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = var.subnet_id
  tags          = var.tags
}

resource "aws_eip" "this" {
  vpc = true
  tags = var.tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_route" "this" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "this" {
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.this.id
}