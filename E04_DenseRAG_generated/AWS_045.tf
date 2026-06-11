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

resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "main" {
  family                = var.task_definition_name
  cpu                    = var.task_definition_cpu
  memory                = var.task_definition_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = var.task_definition_execution_role_arn
  container_definitions = jsonencode([
    {
      name      = var.container_name
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
}

resource "aws_ecs_service" "main" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.main.name
  task_definition = aws_ecs_task_definition.main.arn
  launch_type      = "FARGATE"
  desired_count    = var.ecs_service_desired_count

  network_configuration {
    security_groups  = [var.security_group_id]
    subnets          = [var.subnet_id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_ecs_task_definition.main]
}

resource "aws_alb" "main" {
  name            = var.alb_name
  subnets         = [var.subnet_id]
  security_groups = [var.security_group_id]
}

resource "aws_alb_target_group" "main" {
  name     = var.target_group_name
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type             = "forward"
  }
}

variable "region" {
  type        = string
  default     = "us-west-2"
}

variable "ecs_cluster_name" {
  type        = string
  default     = "my-ecs-cluster"
}

variable "task_definition_name" {
  type        = string
  default     = "my-task-definition"
}

variable "task_definition_cpu" {
  type        = string
  default     = "256"
}

variable "task_definition_memory" {
  type        = string
  default     = "512"
}

variable "task_definition_execution_role_arn" {
  type        = string
}

variable "container_name" {
  type        = string
  default     = "my-container"
}

variable "container_image" {
  type        = string
}

variable "container_cpu" {
  type        = string
  default     = "10"
}

variable "container_memory" {
  type        = string
  default     = "512"
}

variable "container_port" {
  type        = number
  default     = 80
}

variable "ecs_service_name" {
  type        = string
  default     = "my-ecs-service"
}

variable "ecs_service_desired_count" {
  type        = number
  default     = 1
}

variable "security_group_id" {
  type        = string
}

variable "subnet_id" {
  type        = string
}

variable "target_group_arn" {
  type        = string
}

variable "alb_name" {
  type        = string
  default     = "my-alb"
}

variable "target_group_name" {
  type        = string
  default     = "my-target-group"
}

variable "vpc_id" {
  type        = string
}