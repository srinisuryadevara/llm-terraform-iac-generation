variable "platform_instance_id" {
  type = string
}

variable "instance_type_services" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "redis_port" {
  type = number
  default = 6379
}

variable "redis_engine_version" {
  type = string
  default = "3.2.10"
}

variable "redis_node_type" {
  type = string
}

variable "redis_num_cache_nodes" {
  type = number
  default = 1
}

variable "redis_parameter_group_name" {
  type = string
  default = "default.redis3.2"
}

resource "aws_elasticache_subnet_group" "cache" {
  name       = "gm-${var.platform_instance_id}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "elasticache" {
  name        = "gm-${var.platform_instance_id}-elasticache-sg"
  description = "Security group for ElastiCache"
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

resource "aws_elasticache_cluster" "services" {
  cluster_id           = "gm-${var.platform_instance_id}"
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  port                 = var.redis_port
  num_cache_nodes      = var.redis_num_cache_nodes
  security_group_ids   = [aws_security_group.elasticache.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
  parameter_group_name = var.redis_parameter_group_name
}