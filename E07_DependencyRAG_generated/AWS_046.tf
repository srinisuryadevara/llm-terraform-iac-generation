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

variable "redis_engine_version" {
  type = string
  default = "3.2.10"
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

resource "aws_security_group" "elasticache" {
  vpc_id = aws_vpc.this.id
  ingress {
    from_port = 6379
    to_port   = 6379
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

resource "aws_elasticache_subnet_group" "cache" {
  name       = "cache-subnet-group"
  subnet_ids = [aws_subnet.private.id]
}

resource "aws_elasticache_cluster" "services" {
  cluster_id           = "gm-${var.platform_instance_id}"
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.instance_type_services
  port                 = 6379
  num_cache_nodes      = 1
  security_group_ids   = [aws_security_group.elasticache.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
  parameter_group_name = "default.redis3.2"
}