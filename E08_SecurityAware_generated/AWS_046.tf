provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "private_subnet_cidr" {
  type        = string
  description = "Private subnet CIDR"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "redis_node_type" {
  type        = string
  description = "Redis node type"
}

variable "redis_port" {
  type        = number
  description = "Redis port"
}

variable "redis_parameter_group_name" {
  type        = string
  description = "Redis parameter group name"
}

variable "redis_cluster_id" {
  type        = string
  description = "Redis cluster ID"
}

variable "redis_instance_count" {
  type        = number
  description = "Redis instance count"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "private" {
  cidr_block = var.private_subnet_cidr
  vpc_id     = aws_vpc.this.id
  availability_zone = "${var.region}a"
  tags = {
    Name        = "${var.project}-${var.environment}-private-subnet"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-${var.environment}-redis-sg"
  description = "Redis security group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-redis-sg"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "ssh" {
  name        = "${var.project}-${var.environment}-ssh-sg"
  description = "SSH security group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_source_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-ssh-sg"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = var.redis_cluster_id
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_instance_count
  parameter_group_name = var.redis_parameter_group_name
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id, aws_security_group.ssh.id]
  tags = {
    Name        = "${var.project}-${var.environment}-redis-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.project}-${var.environment}-redis-subnet-group"
  description = "Redis subnet group"
  subnet_ids = [aws_subnet.private.id]
  tags = {
    Name        = "${var.project}-${var.environment}-redis-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_kms_key" "this" {
  description             = "KMS key for Redis encryption"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.project}-${var.environment}-redis-kms-key"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project}-${var.environment}-redis-kms-key"
  target_key_id = aws_kms_key.this.key_id
}