provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  type        = string
  sensitive   = true
}

variable "redis_cluster_id" {
  type        = string
}

variable "redis_node_type" {
  type        = string
}

variable "redis_engine_version" {
  type        = string
}

variable "redis_port" {
  type        = number
}

variable "redis_parameter_group_name" {
  type        = string
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.redis_cluster_id
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = var.redis_parameter_group_name
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  tags = {
    Name        = "redis-cluster"
    Environment = "dev"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = [var.subnet_id]
  tags = {
    Name        = "redis-subnet-group"
    Environment = "dev"
  }
}

resource "aws_security_group" "redis" {
  name        = "redis-security-group"
  description = "Security group for Redis cluster"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "redis-security-group"
    Environment = "dev"
  }

  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_elasticache_cluster" "redis_with_security_group" {
  cluster_id           = var.redis_cluster_id
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = var.redis_parameter_group_name
  port                 = var.redis_port
  security_group_ids   = [aws_security_group.redis.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  tags = {
    Name        = "redis-cluster-with-security-group"
    Environment = "dev"
  }
}

output "redis_cluster_id" {
  value       = aws_elasticache_cluster.redis.cluster_id
  description = "The ID of the Redis cluster"
}

output "redis_cluster_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "The endpoint of the Redis cluster"
}

output "redis_security_group_id" {
  value       = aws_security_group.redis.id
  description = "The ID of the Redis security group"
}