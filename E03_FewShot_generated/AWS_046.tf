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
  description = "Subnet ID"
}

variable "redis_cluster_id" {
  type        = string
  description = "Redis Cluster ID"
}

variable "redis_node_type" {
  type        = string
  description = "Redis Node Type"
}

variable "redis_port" {
  type        = number
  description = "Redis Port"
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.redis_cluster_id
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = [var.subnet_id]
}

resource "aws_security_group" "redis" {
  name        = "redis-security-group"
  description = "Security Group for Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/16",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}