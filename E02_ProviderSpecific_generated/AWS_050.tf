provider "aws" {
  region = var.region
}

variable "region" {
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

variable "cluster_id" {
  type        = string
  description = "ElastiCache Cluster ID"
}

variable "node_type" {
  type        = string
  description = "ElastiCache Node Type"
}

variable "engine_version" {
  type        = string
  description = "ElastiCache Engine Version"
}

variable "port" {
  type        = number
  description = "ElastiCache Port"
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  node_type            = var.node_type
  engine_version       = var.engine_version
  port                 = var.port
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  subnet_group_name   = aws_elasticache_subnet_group.this.name
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "redis-subnet-group"
  subnet_ids = [var.subnet_id]
}

resource "aws_security_group" "this" {
  name        = "redis-sg"
  description = "Security Group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.port
    to_port   = var.port
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

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  node_type            = var.node_type
  engine_version       = var.engine_version
  port                 = var.port
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  subnet_group_name   = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]
}