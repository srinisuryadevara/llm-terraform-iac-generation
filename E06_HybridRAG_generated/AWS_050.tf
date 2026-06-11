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

variable "prefix" {
  type = string
}

variable "ipv4_cidr" {
  type = string
}

variable "ipv4_cidr_newbits" {
  type = number
}

variable "subnets_number" {
  type = number
}

provider "aws" {
  region = "us-west-2"
}

module "network" {
  source = "git@github.com:ccscshq/terraform-aws-network.git?ref=v0.2.0"

  prefix                 = var.prefix
  ipv4_cidr              = var.ipv4_cidr
  ipv4_cidr_newbits      = var.ipv4_cidr_newbits
  subnets_number         = var.subnets_number
  create_private_subnets = true
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.app_name_prefix}-redis-subnet-${var.environment}"
  subnet_ids = module.network.private_subnet_ids

  tags = merge({ Name = "${var.app_name_prefix}-redis-subnet-${var.environment}" }, var.tags)
}

resource "aws_security_group" "elasticache" {
  name        = "${var.app_name_prefix}-elasticache-sg"
  description = "Security group for ElastiCache"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    cidr_blocks = [
      module.network.vpc_cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.app_name_prefix}-elasticache-sg" }, var.tags)
}

resource "aws_elasticache_cluster" "services" {
  cluster_id           = "gm-${var.platform_instance_id}"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.instance_type_services
  port                 = var.redis_port
  num_cache_nodes      = var.num_cache_nodes
  security_group_ids   = [aws_security_group.elasticache.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
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