provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS Cluster Name"
}

variable "ecs_task_definition_family" {
  type        = string
  description = "ECS Task Definition Family"
}

variable "ecs_task_definition_cpu" {
  type        = string
  description = "ECS Task Definition CPU"
}

variable "ecs_task_definition_memory" {
  type        = string
  description = "ECS Task Definition Memory"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS Service Name"
}

variable "alb_name" {
  type        = string
  description = "ALB Name"
}

variable "alb_target_group_name" {
  type        = string
  description = "ALB Target Group Name"
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB Listener ARN"
}

variable "container_name" {
  type        = string
  description = "Container Name"
}

variable "container_port" {
  type        = number
  description = "Container Port"
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.ecs_task_definition_family
  cpu                      = var.ecs_task_definition_cpu
  memory                   = var.ecs_task_definition_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image      = "nginx:latest"
      cpu        = var.ecs_task_definition_cpu
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

resource "aws_iam_role" "ecs_task_execution" {
  name        = "ecs-task-execution"
  description = "ECS Task Execution Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.this.id]
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_alb_listener_rule.this]
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = [aws_subnet.this.id]
  security_groups = [aws_security_group.this.id]
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
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

resource "aws_alb_listener_rule" "this" {
  listener_arn = aws_alb_listener.this.arn
  priority     = 1

  action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}