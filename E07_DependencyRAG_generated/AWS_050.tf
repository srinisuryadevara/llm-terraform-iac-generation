variable "platform_instance_id" {
  type = string
}

variable "instance_type_services" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "subnet_cidr" {
  type = string
}

variable "redis_port" {
  type = number
  default = 6379
}

variable "redis_engine_version" {
  type = string
  default = "3.2.10"
}

variable "redis_parameter_group_name" {
  type = string
  default = "default.redis3.2"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zones[0]
}

resource "aws_elasticache_subnet_group" "cache" {
  name        = "cache-subnet-group"
  description = "ElastiCache subnet group"
  subnet_ids  = [aws_subnet.private.id]
}

resource "aws_security_group" "elasticache" {
  name        = "elasticache-sg"
  description = "ElastiCache security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
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
  node_type            = var.instance_type_services
  port                 = var.redis_port
  num_cache_nodes      = 1
  security_group_ids   = [aws_security_group.elasticache.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
  parameter_group_name = var.redis_parameter_group_name
}