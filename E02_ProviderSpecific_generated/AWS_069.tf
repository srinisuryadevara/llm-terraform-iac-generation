provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  type        = list(string)
  sensitive   = true
}

variable "alb_listener_arn" {
  type        = string
  sensitive   = true
}

variable "alb_target_group_arn" {
  type        = string
  sensitive   = true
}

variable "ecs_task_execution_role_arn" {
  type        = string
  sensitive   = true
}

variable "ecs_task_definition_family" {
  type        = string
  sensitive   = false
  default     = "my-ecs-task-definition"
}

variable "ecs_service_name" {
  type        = string
  sensitive   = false
  default     = "my-ecs-service"
}

variable "ecs_service_desired_count" {
  type        = number
  sensitive   = false
  default     = 1
}

variable "ecs_container_name" {
  type        = string
  sensitive   = false
  default     = "my-ecs-container"
}

variable "ecs_container_image" {
  type        = string
  sensitive   = false
  default     = "nginx:latest"
}

variable "ecs_container_port" {
  type        = number
  sensitive   = false
  default     = 80
}

resource "aws_ecs_cluster" "this" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_family
  requires_compatibilities = ["FARGATE"]
  network_mode           = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([
    {
      name        = var.ecs_container_name
      image       = var.ecs_container_image
      cpu         = 10
      essential   = true
      portMappings = [
        {
          containerPort = var.ecs_container_port
          hostPort      = var.ecs_container_port
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
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.this.id]
    subnets           = var.subnet_ids
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.ecs_container_name
    container_port   = var.ecs_container_port
  }

  depends_on = [aws_ecs_task_definition.this]
}

resource "aws_security_group" "this" {
  name        = "my-ecs-security-group"
  description = "Allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.ecs_container_port
    to_port     = var.ecs_container_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "this" {
  name     = "my-alb-target-group"
  port     = var.ecs_container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = var.alb_listener_arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}