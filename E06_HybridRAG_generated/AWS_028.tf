variable "platform_instance_id" {
  type = string
}

variable "instance_type_services" {
  type = string
}

variable "app_name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "redis_cluster" {
  type = string
}

variable "node_type" {
  type = string
}

variable "parameter_group_name" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "num_cache_nodes" {
  type = number
}

variable "redis_port" {
  type = number
}

variable "maintenance_window" {
  type = string
}

variable "transit_encryption_enabled" {
  type = bool
}

variable "auth_token" {
  type = string
  sensitive = true
}

variable "at_rest_encryption_enabled" {
  type = bool
}

variable "kms" {
  type = string
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.app_name_prefix}-vpc"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "${var.app_name_prefix}-private-subnet"
  }
}

resource "aws_security_group" "elasticache" {
  name        = "${var.app_name_prefix}-elasticache-sg"
  description = "Security group for ElastiCache"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.1.0/24"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name_prefix}-elasticache-sg"
  }
}

resource "aws_elasticache_subnet_group" "cache" {
  name       = "${var.app_name_prefix}-redis-subnet-${var.environment}"
  subnet_ids = [aws_subnet.private.id]

  tags = merge({ Name = "${var.app_name_prefix}-redis-subnet-${var.environment}" }, var.tags)
}

resource "aws_elasticache_cluster" "services" {
  cluster_id           = "gm-${var.platform_instance_id}"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.instance_type_services
  port                 = var.redis_port
  num_cache_nodes      = var.num_cache_nodes
  security_group_ids   = [aws_security_group.elasticache.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
  parameter_group_name = var.parameter_group_name
}

resource "aws_elasticache_replication_group" "redis_replication_group" {
  replication_group_id       = var.redis_cluster
  automatic_failover_enabled = true
  engine                     = "redis"
  node_type                  = var.node_type
  parameter_group_name       = var.parameter_group_name
  engine_version             = var.engine_version
  num_cache_clusters         = var.num_cache_nodes
  port                       = var.redis_port
  maintenance_window         = var.maintenance_window
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.kms
}