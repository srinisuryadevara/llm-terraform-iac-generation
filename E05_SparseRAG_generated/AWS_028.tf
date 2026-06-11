provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr_block

  tags = {
    Name = var.private_subnet_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = var.nat_eip_name
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.private.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.private_route_table_name
  }
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.nat.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "elasticache" {
  name        = var.elasticache_security_group_name
  description = "Security group for ElastiCache"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"
    cidr_blocks = [
      var.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.elasticache_security_group_name
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = var.elasticache_subnet_group_name
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name = var.elasticache_subnet_group_name
  }
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
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.elasticache.id]
}

variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/18"
}

variable "vpc_name" {
  type        = string
  default     = "Main VPC"
}

variable "private_cidr_block" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_name" {
  type        = string
  default     = "Private Subnet"
}

variable "igw_name" {
  type        = string
  default     = "Main IGW"
}

variable "nat_eip_name" {
  type        = string
  default     = "NAT Gateway EIP"
}

variable "private_route_table_name" {
  type        = string
  default     = "Private Route Table"
}

variable "elasticache_security_group_name" {
  type        = string
  default     = "ElastiCache Security Group"
}

variable "elasticache_subnet_group_name" {
  type        = string
  default     = "ElastiCache Subnet Group"
}

variable "redis_cluster" {
  type        = string
  default     = "redis-cluster"
}

variable "node_type" {
  type        = string
  default     = "cache.t2.micro"
}

variable "parameter_group_name" {
  type        = string
  default     = "default.redis6.x"
}

variable "engine_version" {
  type        = string
  default     = "6.2"
}

variable "num_cache_nodes" {
  type        = number
  default     = 1
}

variable "redis_port" {
  type        = number
  default     = 6379
}

variable "maintenance_window" {
  type        = string
  default     = "sun:02:00-sun:03:00"
}

variable "transit_encryption_enabled" {
  type        = bool
  default     = true
}

variable "auth_token" {
  type        = string
  sensitive   = true
}

variable "at_rest_encryption_enabled" {
  type        = bool
  default     = true
}

variable "kms" {
  type        = string
  sensitive   = true
}