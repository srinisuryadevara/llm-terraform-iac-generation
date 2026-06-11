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

resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = var.redis_cluster_id
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_security_group.id]
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.redis_cluster_id}-subnet-group"
  subnet_ids = [var.subnet_id]
}

resource "aws_security_group" "redis_security_group" {
  name        = "${var.redis_cluster_id}-security-group"
  description = "Security group for Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}