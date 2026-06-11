terraform {
  required_version = "1.3.9"
}

provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
}

variable "ami_id" {
  type        = string
  description = "EC2 AMI ID"
}

data "aws_ssm_parameter" "linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "subnet-1"
  }
}

resource "aws_security_group" "security_group" {
  name        = "security-group"
  description = "Security Group for EC2 Instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-group"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ec2-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ssm_parameter.linux_ami.value
  instance_type = var.instance_type
  key_name      = aws_key_pair.key_pair.key_name
  subnet_id     = aws_subnet.subnet_1.id
  vpc_security_group_ids = [
    aws_security_group.security_group.id
  ]

  tags = {
    Name = "ec2-instance"
  }
}