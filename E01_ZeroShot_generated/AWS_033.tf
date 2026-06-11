provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS Cluster Name"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS Service Name"
}

variable "ecs_task_definition_name" {
  type        = string
  description = "ECS Task Definition Name"
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

variable "ecs_container_name" {
  type        = string
  description = "ECS Container Name"
}

variable "ecs_container_image" {
  type        = string
  description = "ECS Container Image"
}

variable "ecs_container_port" {
  type        = number
  description = "ECS Container Port"
}

variable "alb_name" {
  type        = string
  description = "ALB Name"
}

variable "alb_listener_port" {
  type        = number
  description = "ALB Listener Port"
}

variable "alb_listener_protocol" {
  type        = string
  description = "ALB Listener Protocol"
}

variable "alb_target_group_name" {
  type        = string
  description = "ALB Target Group Name"
}

variable "alb_target_group_port" {
  type        = number
  description = "ALB Target Group Port"
}

variable "alb_target_group_protocol" {
  type        = string
  description = "ALB Target Group Protocol"
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_family
  cpu                    = var.ecs_task_definition_cpu
  memory                 = var.ecs_task_definition_memory
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn     = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name        = var.ecs_container_name
      image       = var.ecs_container_image
      cpu         = var.ecs_task_definition_cpu
      memory      = var.ecs_task_definition_memory
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

resource "aws_iam_role" "ecs_task_execution" {
  name        = "ecs-task-execution"
  description = "ECS Task Execution Role"

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

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = "ENABLED"
  }
  desired_count = 1
}

resource "aws_security_group" "ecs" {
  name        = "ecs"
  description = "ECS Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.ecs_container_port
    to_port     = var.ecs_container_port
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

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    protocol    = var.alb_listener_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = var.alb_target_group_port
  }
}

resource "aws_alb_target_group_attachment" "this" {
  target_group_arn = aws_alb_target_group.this.arn
  target_id       = aws_ecs_service.this.id
  port            = var.alb_target_group_port
}