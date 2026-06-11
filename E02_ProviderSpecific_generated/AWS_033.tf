provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ecs_task_execution_role_arn" {
  type = string
}

variable "ecs_task_definition_family" {
  type = string
}

variable "ecs_task_definition_cpu" {
  type = string
}

variable "ecs_task_definition_memory" {
  type = string
}

variable "ecs_task_definition_container_name" {
  type = string
}

variable "ecs_task_definition_container_image" {
  type = string
}

variable "ecs_task_definition_container_port" {
  type = number
}

variable "alb_name" {
  type = string
}

variable "alb_listener_port" {
  type = number
}

variable "alb_listener_protocol" {
  type = string
}

variable "alb_target_group_name" {
  type = string
}

variable "alb_target_group_port" {
  type = number
}

variable "alb_target_group_protocol" {
  type = string
}

resource "aws_ecs_cluster" "this" {
  name = "ecs-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_family
  cpu                    = var.ecs_task_definition_cpu
  memory                 = var.ecs_task_definition_memory
  network_mode           = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([
    {
      name      = var.ecs_task_definition_container_name
      image      = var.ecs_task_definition_container_image
      cpu        = 10
      essential = true
      portMappings = [
        {
          containerPort = var.ecs_task_definition_container_port
          hostPort      = var.ecs_task_definition_container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.this.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = var.ecs_task_definition_container_name
    container_port   = var.ecs_task_definition_container_port
  }
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.this.id]
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group" "this" {
  name     = var.alb_target_group_name
  port     = var.alb_target_group_port
  protocol = var.alb_target_group_protocol
  vpc_id   = var.vpc_id
}

resource "aws_security_group" "this" {
  name        = "ecs-security-group"
  description = "ECS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}