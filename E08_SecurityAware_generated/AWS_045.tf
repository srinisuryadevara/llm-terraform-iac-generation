provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ECS Task Execution Role ARN"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "ECS Task Role ARN"
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB Listener ARN"
}

variable "alb_target_group_arn" {
  type        = string
  description = "ALB Target Group ARN"
}

variable "container_port" {
  type        = number
  description = "Container Port"
}

variable "container_image" {
  type        = string
  description = "Container Image"
}

variable "container_cpu" {
  type        = number
  description = "Container CPU"
}

variable "container_memory" {
  type        = number
  description = "Container Memory"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "this" {
  count             = length(var.subnet_cidrs)
  cidr_block        = var.subnet_cidrs[count.index]
  vpc_id            = aws_vpc.this.id
  availability_zone = "${var.region}${count.index % 3 + 1}"
  tags = {
    Name        = "${var.project}-${var.environment}-subnet-${count.index}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-sg"
  description = "Security Group for ECS Fargate"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-sg"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-cluster"
  tags = {
    Name        = "${var.project}-${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_task_definition" "this" {
  family                = "${var.project}-${var.environment}-task"
  cpu                   = var.container_cpu
  memory                = var.container_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = var.ecs_task_execution_role_arn
  task_role_arn         = var.ecs_task_role_arn
  container_definitions = jsonencode([
    {
      name      = "${var.project}-${var.environment}-container"
      image      = var.container_image
      cpu        = var.container_cpu
      memory    = var.container_memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
  tags = {
    Name        = "${var.project}-${var.environment}-task"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project}-${var.environment}-service"
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  launch_type      = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.this.id]
    subnets          = aws_subnet.this.*.id
    assign_public_ip = "ENABLED"
  }
  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "${var.project}-${var.environment}-container"
    container_port   = var.container_port
  }
  depends_on = [aws_ecs_task_definition.this]
  tags = {
    Name        = "${var.project}-${var.environment}-service"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = var.alb_listener_arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = var.alb_target_group_arn
  }
  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-listener-rule"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_kms_key" "this" {
  description             = "KMS Key for ECS Fargate"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.project}-${var.environment}-kms-key"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-${var.environment}-bucket"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name        = "${var.project}-${var.environment}-bucket"
    Environment = var.environment
    Project     = var.project
  }
}