provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "app_name_prefix" {
  type        = string
  description = "Application name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR block"
}

variable "private_subnet_cidr" {
  type        = string
  description = "Private subnet CIDR block"
}

variable "redis_cluster" {
  type        = string
  description = "Redis cluster ID"
}

variable "node_type" {
  type        = string
  description = "Redis node type"
}

variable "parameter_group_name" {
  type        = string
  description = "Redis parameter group name"
}

variable "engine_version" {
  type        = string
  description = "Redis engine version"
}

variable "num_cache_nodes" {
  type        = number
  description = "Number of Redis cache nodes"
}

variable "redis_port" {
  type        = number
  description = "Redis port"
}

variable "maintenance_window" {
  type        = string
  description = "Redis maintenance window"
}

variable "transit_encryption_enabled" {
  type        = bool
  description = "Redis transit encryption enabled"
}

variable "auth_token" {
  type        = string
  description = "Redis auth token"
}

variable "at_rest_encryption_enabled" {
  type        = bool
  description = "Redis at rest encryption enabled"
}

variable "kms" {
  type        = string
  description = "KMS key ID"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge({ Name = "${var.app_name_prefix}-vpc-${var.environment}" }, var.tags)
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr

  tags = merge({ Name = "${var.app_name_prefix}-public-subnet-${var.environment}" }, var.tags)
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr

  tags = merge({ Name = "${var.app_name_prefix}-private-subnet-${var.environment}" }, var.tags)
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge({ Name = "${var.app_name_prefix}-igw-${var.environment}" }, var.tags)
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]

  tags = merge({ Name = "${var.app_name_prefix}-nat-eip-${var.environment}" }, var.tags)
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = merge({ Name = "${var.app_name_prefix}-nat-${var.environment}" }, var.tags)
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.app_name_prefix}-redis-subnet-${var.environment}"
  subnet_ids = [aws_subnet.private.id]

  tags = merge({ Name = "${var.app_name_prefix}-redis-subnet-${var.environment}" }, var.tags)
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

  tags = merge({ Name = "${var.app_name_prefix}-redis-replication-group-${var.environment}" }, var.tags)
}