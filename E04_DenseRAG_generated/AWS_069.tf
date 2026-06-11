terraform {
  required_version = ">= 1.4, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                = var.task_definition_name
  cpu                    = var.task_definition_cpu
  memory                = var.task_definition_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = var.task_definition_execution_role_arn
  container_definitions = jsonencode([
    {
      name        = var.container_name
      image       = var.container_image
      cpu         = var.container_cpu
      memory      = var.container_memory
      essential   = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_service_desired_count
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_alb_listener.this]
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnets
  security_groups = var.security_groups
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "task_definition_name" {
  type        = string
  description = "Task definition name"
}

variable "task_definition_cpu" {
  type        = string
  description = "Task definition CPU"
}

variable "task_definition_memory" {
  type        = string
  description = "Task definition memory"
}

variable "task_definition_execution_role_arn" {
  type        = string
  description = "Task definition execution role ARN"
}

variable "container_name" {
  type        = string
  description = "Container name"
}

variable "container_image" {
  type        = string
  description = "Container image"
}

variable "container_cpu" {
  type        = string
  description = "Container CPU"
}

variable "container_memory" {
  type        = string
  description = "Container memory"
}

variable "container_port" {
  type        = number
  description = "Container port"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name"
}

variable "ecs_service_desired_count" {
  type        = number
  description = "ECS service desired count"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets"
}

variable "security_groups" {
  type        = list(string)
  description = "Security groups"
}

variable "alb_name" {
  type        = string
  description = "ALB name"
}

variable "alb_target_group_name" {
  type        = string
  description = "ALB target group name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}