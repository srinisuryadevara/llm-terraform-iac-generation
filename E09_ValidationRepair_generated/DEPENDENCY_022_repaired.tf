provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR"
}

variable "security_group_name" {
  type        = string
  description = "Security Group Name"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR blocks for security group"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "example-subnet"
  }
}

resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id
  name   = var.security_group_name
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }
  tags = {
    Name = "example-security-group"
  }
}

resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.this.id
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  tags = {
    Name = "example-ec2-instance"
  }
}

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "subnet_id" {
  value       = aws_subnet.this.id
  description = "Subnet ID"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security Group ID"
}

output "instance_id" {
  value       = aws_instance.this.id
  description = "EC2 Instance ID"
}