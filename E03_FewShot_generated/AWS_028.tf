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
  description = "Private Subnet ID"
}

variable "redis_cluster_id" {
  type        = string
  description = "ElastiCache Redis Cluster ID"
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis Node Type"
}

variable "redis_port" {
  type        = number
  description = "ElastiCache Redis Port"
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.redis_cluster_id
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  availability_zone    = "${var.aws_region}a"
  maintenance_window   = "mon:10:30-mon:11:30"
  snapshot_window      = "10:00-11:00"
  snapshot_retention_limit = 7
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = [var.subnet_id]
}

resource "aws_security_group" "redis" {
  name        = "redis-security-group"
  description = "Security Group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_cluster_parameter_group" "redis" {
  name        = "redis-parameter-group"
  family      = "redis6.x"
  description = "Parameter Group for ElastiCache Redis"

  parameter {
    name  = "cluster-enabled"
    value = "yes"
  }

  parameter {
    name  = "cluster-node-timeout"
    value = "10000"
  }
}

resource "aws_elasticache_cluster" "redis_parameter_group" {
  cluster_id           = aws_elasticache_cluster.redis.cluster_id
  parameter_group_name = aws_elasticache_cluster_parameter_group.redis.name
}