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

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR for ElastiCache"
}

variable "instance_type" {
  type        = string
  description = "Instance type for ElastiCache"
}

variable "cluster_id" {
  type        = string
  description = "ElastiCache Cluster ID"
}

variable "engine_version" {
  type        = string
  description = "Redis Engine Version"
}

variable "port" {
  type        = number
  description = "Redis Port"
}

variable "parameter_group_name" {
  type        = string
  description = "Parameter Group Name"
}

variable "maintenance_window" {
  type        = string
  description = "Maintenance Window"
}

variable "snapshot_window" {
  type        = string
  description = "Snapshot Window"
}

variable "snapshot_retention_limit" {
  type        = number
  description = "Snapshot Retention Limit"
}

variable "tags" {
  type        = map(string)
  description = "Tags for ElastiCache"
}

resource "aws_security_group" "elasticache" {
  name        = "elasticache-sg"
  description = "Security Group for ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.port
    to_port   = var.port
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

  tags = var.tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.instance_type
  num_cache_nodes      = 1
  parameter_group_name = var.parameter_group_name
  port                 = var.port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.elasticache.id]
  maintenance_window   = var.maintenance_window
  snapshot_window      = var.snapshot_window
  snapshot_retention_limit = var.snapshot_retention_limit
  at_rest_encryption_enabled = true
  transit_encryption_enabled  = true

  tags = var.tags
}

resource "aws_elasticache_subnet_group" "redis" {
  name        = "redis-subnet-group"
  description = "Subnet Group for ElastiCache"
  subnet_ids = [
    var.subnet_id
  ]

  tags = var.tags
}