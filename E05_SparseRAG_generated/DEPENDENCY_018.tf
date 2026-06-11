variable "name" {
  type        = string
  description = "The name of the service"
}

variable "cpu" {
  type        = number
  description = "The CPU allocation for the service"
}

variable "memory" {
  type        = number
  description = "The memory allocation for the service"
}

variable "load_balancer" {
  type        = string
  description = "The ARN of the load balancer"
}

variable "hostname" {
  type        = string
  description = "The hostname of the service"
}

variable "network" {
  type        = string
  description = "The ID of the network"
}

variable "cluster_arn" {
  type        = string
  description = "The ARN of the ECS cluster"
}

variable "task_definition_arn" {
  type        = string
  description = "The ARN of the task definition"
}

variable "target_group_arn" {
  type        = string
  description = "The ARN of the target group"
}

locals {
  port = 80
  container_definitions_json = jsonencode([
    {
      name        = var.name
      image       = "nginx:latest"
      cpu         = var.cpu
      memory      = var.memory
      essential   = true
      portMappings = [
        {
          containerPort = local.port
          hostPort      = local.port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_cluster" "service" {
  name = var.name
}

resource "aws_ecs_task_definition" "service" {
  family                   = var.name
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions    = local.container_definitions_json
}

resource "aws_iam_role" "ecs_task_execution" {
  name        = "${var.name}-ecs-task-execution"
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

resource "aws_ecs_service" "service" {
  name            = var.name
  cluster         = aws_ecs_cluster.service.arn
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = [var.network]
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = local.port
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}

resource "aws_security_group" "service" {
  name        = var.name
  description = "Security group for the service"
  vpc_id      = var.network

  ingress {
    from_port   = local.port
    to_port     = local.port
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