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

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR for Redis access"
}

variable "redis_node_type" {
  type        = string
  description = "Redis Node Type"
}

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Redis Port"
}

variable "redis_parameter_group_name" {
  type        = string
  description = "Redis Parameter Group Name"
}

variable "redis_snapshot_window" {
  type        = string
  description = "Redis Snapshot Window"
}

variable "redis_snapshot_retention_limit" {
  type        = number
  description = "Redis Snapshot Retention Limit"
}

variable "redis_at_rest_encryption_enabled" {
  type        = bool
  default     = true
  description = "Redis At Rest Encryption Enabled"
}

variable "redis_transit_encryption_enabled" {
  type        = bool
  default     = true
  description = "Redis Transit Encryption Enabled"
}

variable "kms_key_id" {
  type        = string
  description = "KMS Key ID for Redis Encryption"
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project}-${var.environment}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = var.redis_parameter_group_name
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  snapshot_window      = var.redis_snapshot_window
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
  transit_encryption_enabled  = var.redis_transit_encryption_enabled
  kms_key_id              = var.kms_key_id
  tags = {
    Name        = "${var.project}-${var.environment}-redis"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-${var.environment}-redis-subnet-group"
  subnet_ids = [var.subnet_id]
  tags = {
    Name        = "${var.project}-${var.environment}-redis-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-${var.environment}-redis-sg"
  description = "Redis Security Group"
  vpc_id      = var.vpc_id
  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    cidr_blocks = [var.allowed_cidr]
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

resource "aws_elasticache_cluster_parameter_group" "redis" {
  name   = "${var.project}-${var.environment}-redis-parameter-group"
  family = "redis6.x"
  parameter {
    name  = "tls-version"
    value = "1.2"
  }
  tags = {
    Name        = "${var.project}-${var.environment}-redis-parameter-group"
    Environment = var.environment
    Project     = var.project
  }
}