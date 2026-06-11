terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_db_instance" "rds_instance" {
  identifier           = var.identifier
  instance_class       = var.instance_class
  engine               = var.engine
  engine_version       = var.engine_version
  username             = var.username
  password             = var.password
  publicly_accessible  = false
  vpc_security_group_ids = [var.security_group_id]
  storage_type         = var.storage_type
  allocated_storage    = var.allocated_storage
  skip_final_snapshot  = true
  deletion_protection  = false
  storage_encrypted    = true
  kms_key_id           = var.kms_key_id
  tags = {
    Name        = var.identifier
    Environment = var.environment
  }
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "identifier" {
  type        = string
  sensitive   = true
}

variable "instance_class" {
  type        = string
  sensitive   = true
}

variable "engine" {
  type        = string
  sensitive   = true
}

variable "engine_version" {
  type        = string
  sensitive   = true
}

variable "username" {
  type        = string
  sensitive   = true
}

variable "password" {
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  type        = string
  sensitive   = true
}

variable "storage_type" {
  type        = string
  sensitive   = true
}

variable "allocated_storage" {
  type        = number
  sensitive   = true
}

variable "kms_key_id" {
  type        = string
  sensitive   = true
}

variable "environment" {
  type        = string
  sensitive   = true
}