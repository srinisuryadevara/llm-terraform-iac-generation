# Variables
variable "name" {
  type        = string
  description = "Name of the service"
}

variable "cpu" {
  type        = number
  description = "CPU allocation for the task"
}

variable "memory" {
  type        = number
  description = "Memory allocation for the task"
}

variable "load_balancer" {
  type        = string
  description = "ARN of the load balancer"
}

variable "hostname" {
  type        = string
  description = "Hostname for the service"
}

variable "network" {
  type        = string
  description = "ID of the network"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "sys_name" {
  type        = string
  description = "System name"
}

variable "app_ctr_img_tag" {
  type        = string
  description = "Tag of the application container image"
}

variable "api_ctr_img_tag" {
  type        = string
  description = "Tag of the API container image"
}

# CloudWatch Resources
resource "aws_cloudwatch_log_group" "app_task_loggrp" {
  name = "/ecs/${var.sys_name}-app-task"
}

resource "aws_cloudwatch_log_group" "api_task_loggrp" {
  name = "/ecs/${var.sys_name}-api-task"
}

# ECS Resources
resource "aws_ecs_cluster" "app_ctr_cluster" {
  name = "${var.sys_name}-app-ctr-cluster"
}

resource "aws_ecs_cluster" "api_ctr_cluster" {
  name = "${var.sys_name}-api-ctr-cluster"
}

# IAM Resources
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_ecsTaskExecutionRole" {
  name               = "${var.sys_name}-app-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role" "api_ecsTaskExecutionRole" {
  name               = "${var.sys_name}-api-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "app_ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.app_ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "api_ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.api_ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECR Resources
resource "aws_ecr_repository" "app_ctr_img_repo" {
  name = "${var.sys_name}-app-ctr-img-repo"
}

resource "aws_ecr_repository" "api_ctr_img_repo" {
  name = "${var.sys_name}-api-ctr-img-repo"
}

data "aws_ecr_image" "app_image" {
  repository_name = aws_ecr_repository.app_ctr_img_repo.name
  image_tag       = var.app_ctr_img_tag
}

data "aws_ecr_image" "api_image" {
  repository_name = aws_ecr_repository.api_ctr_img_repo.name
  image_tag       = var.api_ctr_img_tag
}

# Task Definitions
resource "aws_ecs_task_definition" "app_taskdef" {
  family                   = "${var.sys_name}-app-taskdef"
  container_definitions    = jsonencode([
    {
      name        = "${var.sys_name}-app-task",
      image       = "${aws_ecr_repository.app_ctr_img_repo.repository_url}@${data.aws_ecr_image.app_image.image_digest}",
      essential   = true,
      portMappings = [
        {
          containerPort = 3000,
          hostPort      = 3000
        }
      ],
      memory = 512,
      cpu    = 256,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app_task_loggrp.name,
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.app_ecsTaskExecutionRole.arn
}

resource "aws_ecs_task_definition" "api_taskdef" {
  family                   = "${var.sys_name}-api-taskdef"
  container_definitions    = jsonencode([
    {
      name        = "${var.sys_name}-api-task",
      image       = "${aws_ecr_repository.api_ctr_img_repo.repository_url}@${data.aws_ecr_image.api_image.image_digest}",
      essential   = true,
      portMappings = [
        {
          containerPort = 3000,
          hostPort      = 3000
        }
      ],
      memory = 512,
      cpu    = 256,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api_task_loggrp.name,
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.api_ecsTaskExecutionRole.arn
}

# ALB Resources
resource "aws_alb" "app_alb" {
  name            = "${var.sys_name}-app-alb"
  subnets         = [var.network]
  security_groups = [aws_security_group.app_sg.id]
}

resource "aws_alb" "api_alb" {
  name            = "${var.sys_name}-api-alb"
  subnets         = [var.network]
  security_groups = [aws_security_group.api_sg.id]
}

resource "aws_security_group" "app_sg" {
  name        = "${var.sys_name}-app-sg"
  description = "Security group for the application"
  vpc_id      = var.network

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_security_group" "api_sg" {
  name        = "${var.sys_name}-api-sg"
  description = "Security group for the API"
  vpc_id      = var.network

  ingress {
    from_port   = 3000
    to_port     = 3000
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

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "${var.sys_name}-app-service"
  cluster         = aws_ecs_cluster.app_ctr_cluster.name
  task_definition = aws_ecs_task_definition.app_taskdef.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = [var.network]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app_tg.arn
    container_name   = "${var.sys_name}-app-task"
    container_port   = 3000
  }
}

resource "aws_ecs_service" "api_service" {
  name            = "${var.sys_name}-api-service"
  cluster         = aws_ecs_cluster.api_ctr_cluster.name
  task_definition = aws_ecs_task_definition.api_taskdef.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = [var.network]
    security_groups  = [aws_security_group.api_sg.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.api_tg.arn
    container_name   = "${var.sys_name}-api-task"
    container_port   = 3000
  }
}

# ALB Target Group
resource "aws_alb_target_group" "app_tg" {
  name     = "${var.sys_name}-app-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.network
}

resource "aws_alb_target_group" "api_tg" {
  name     = "${var.sys_name}-api-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   =