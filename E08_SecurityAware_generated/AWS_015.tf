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

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.example.id
  subnet_id     = var.subnet_id
  tags          = var.tags
}

resource "aws_eip" "example" {
  vpc = true
  tags = var.tags
}

resource "aws_internet_gateway" "example" {
  vpc_id = var.vpc_id
  tags   = var.tags
}