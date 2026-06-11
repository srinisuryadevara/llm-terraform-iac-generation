provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "ami_id" {
  type        = string
  description = "ID of AMI"
}

variable "instance_type" {
  type        = string
  description = "Type of EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "ID of existing subnet"
}

variable "security_group_id" {
  type        = string
  description = "ID of existing security group"
}

variable "instance_name" {
  type        = string
  description = "Name of EC2 instance"
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [
    var.security_group_id
  ]
  tags = {
    Name = var.instance_name
  }
}