resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "redis-${var.platform_instance_id}"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.instance_type
  port                 = var.redis_port
  num_cache_nodes      = var.num_cache_nodes
  security_group_ids   = [aws_security_group.elasticache.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  parameter_group_name = var.parameter_group_name
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.app_name_prefix}-redis-subnet-${var.environment}"
  subnet_ids = data.aws_subnets.private_subnets.ids

  tags = merge({ Name = "${var.app_name_prefix}-redis-subnet-${var.environment}" }, var.tags)
}

resource "aws_security_group" "elasticache" {
  name        = "${var.app_name_prefix}-elasticache-sg"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    security_groups = [
      aws_security_group.bastion.id
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

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.app_name_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      var.bastion_cidr
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.app_name_prefix}-bastion-sg" }, var.tags)
}

variable "app_name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "num_cache_nodes" {
  type = number
}

variable "parameter_group_name" {
  type = string
}

variable "bastion_cidr" {
  type = string
}

variable "platform_instance_id" {
  type = string
}

variable "tags" {
  type = map(string)
}