# Configure the AWS Provider
provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

# Create an ECS cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "this" {
  family                = var.task_definition_family
  cpu                   = var.task_definition_cpu
  memory                = var.task_definition_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image      = var.container_image
      cpu        = var.container_cpu
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

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name        = "${var.cluster_name}-ecs-task-execution"
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

# Create an IAM policy for ECS task execution
resource "aws_iam_policy" "ecs_task_execution" {
  name        = "${var.cluster_name}-ecs-task-execution-policy"
  description = "ECS task execution policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

# Create an ALB target group
resource "aws_alb_target_group" "this" {
  name        = var.target_group_name
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

# Create an ECS service
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
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

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "task_definition_family" {
  type        = string
  description = "ECS task definition family"
}

variable "task_definition_cpu" {
  type        = string
  description = "ECS task definition CPU"
}

variable "task_definition_memory" {
  type        = string
  description = "ECS task definition memory"
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

variable "container_port" {
  type        = number
  description = "Container port"
}

variable "target_group_name" {
  type        = string
  description = "ALB target group name"
}

variable "target_group_port" {
  type        = number
  description = "ALB target group port"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets"
}

variable "security_groups" {
  type        = list(string)
  description = "Security groups"
}

variable "desired_count" {
  type        = number
  description = "Desired count"
}

variable "service_name" {
  type        = string
  description = "ECS service name"
}