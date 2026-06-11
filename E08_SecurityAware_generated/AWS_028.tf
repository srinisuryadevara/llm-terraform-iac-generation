provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Private Subnet ID"
}

variable "redis_node_type" {
  type        = string
  description = "Redis Node Type"
}

variable "redis_port" {
  type        = number
  description = "Redis Port"
  default     = 6379
}

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR for Redis Access"
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-${var.environment}-redis-sg"
  description = "Security Group for Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    cidr_blocks = [
      var.allowed_cidr
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-redis-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project}-${var.environment}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
  tags = {
    Name        = "${var.project}-${var.environment}-redis"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.project}-${var.environment}-redis-sg"
  description = "Subnet Group for Redis"
  subnet_ids = [
    var.subnet_id
  ]
  tags = {
    Name        = "${var.project}-${var.environment}-redis-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_key" "redis" {
  description             = "KMS Key for Redis"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.project}-${var.environment}-redis-kms"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "redis" {
  name          = "alias/${var.project}-${var.environment}-redis-kms"
  target_key_id = aws_kms_key.redis.key_id
}