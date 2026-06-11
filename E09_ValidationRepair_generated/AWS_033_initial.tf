provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
}

variable "ecs_cluster_name" {
  type        = string
}

variable "ecs_task_definition_family" {
  type        = string
}

variable "ecs_task_definition_cpu" {
  type        = string
}

variable "ecs_task_definition_memory" {
  type        = string
}

variable "ecs_task_definition_container_name" {
  type        = string
}

variable "ecs_task_definition_container_image" {
  type        = string
}

variable "ecs_task_definition_container_port" {
  type        = number
}

variable "alb_name" {
  type        = string
}

variable "alb_subnets" {
  type        = list(string)
}

variable "alb_security_groups" {
  type        = list(string)
}

variable "alb_target_group_name" {
  type        = string
}

variable "alb_target_group_port" {
  type        = number
}

variable "alb_listener_port" {
  type        = number
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_family
  cpu                    = var.ecs_task_definition_cpu
  memory                = var.ecs_task_definition_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name        = var.ecs_task_definition_container_name
      image       = var.ecs_task_definition_container_image
      cpu         = 10
      essential   = true
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

resource "aws_iam_role" "ecs_task_execution" {
  name        = "ecs-task-execution"
  description = "ECS task execution role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.alb_subnets
  security_groups = var.alb_security_groups
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_target_group_name
  port        = var.alb_target_group_port
  protocol    = "HTTP"
  vpc_id      = aws_alb.this.vpc_id
  target_type = "ip"
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_ecs_service" "this" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.alb_subnets
    security_groups  = var.alb_security_groups
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = var.ecs_task_definition_container_name
    container_port   = var.ecs_task_definition_container_port
  }
}