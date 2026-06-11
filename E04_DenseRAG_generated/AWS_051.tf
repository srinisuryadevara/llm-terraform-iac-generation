terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to place the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Type of the EC2 instance"
}

variable "ami_id" {
  type        = string
  description = "ID of the AMI to use for the EC2 instance"
}

variable "security_group_name" {
  type        = string
  description = "Name of the security group to attach to the EC2 instance"
}

variable "security_group_description" {
  type        = string
  description = "Description of the security group to attach to the EC2 instance"
}

variable "security_group_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "Ingress rules for the security group"
}

resource "aws_security_group" "ec2_security_group" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = data.aws_subnet.subnet.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

data "aws_subnet" "subnet" {
  id = var.subnet_id
}

resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id
  ]

  tags = {
    Name = "EC2 Instance"
  }
}