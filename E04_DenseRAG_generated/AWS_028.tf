variable "platform_instance_id" {
  type        = string
  description = "The ID of the platform instance"
}

variable "instance_type_services" {
  type        = string
  description = "The instance type for the ElastiCache cluster"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the private subnet"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group"
}

resource "aws_elasticache_subnet_group" "cache" {
  name       = "elasticache-subnet-group"
  subnet_ids = [var.subnet_id]
}

resource "aws_elasticache_cluster" "services" {
  cluster_id           = "gm-${var.platform_instance_id}"
  engine               = "redis"
  engine_version       = "6.2"
  node_type            = var.instance_type_services
  port                 = 6379
  num_cache_nodes      = 1
  security_group_ids   = [var.security_group_id]
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
  parameter_group_name = "default.redis6.x"
}

resource "aws_security_group" "elasticache" {
  name        = "elasticache-security-group"
  description = "Security group for ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/16",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elasticache-security-group"
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.example.id
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Security group for example"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "example-security-group"
  }
}

output "elasticache_cluster_id" {
  value = aws_elasticache_cluster.services.cluster_id
}

output "elasticache_cluster_endpoint" {
  value = aws_elasticache_cluster.services.cache_nodes[0].address
}