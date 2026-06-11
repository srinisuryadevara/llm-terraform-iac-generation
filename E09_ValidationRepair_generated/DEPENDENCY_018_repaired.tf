provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "ecs_cluster_name" {
  type        = string
  sensitive   = true
}

variable "ecs_task_definition_name" {
  type        = string
  sensitive   = true
}

variable "alb_target_group_name" {
  type        = string
  sensitive   = true
}

variable "ecs_service_name" {
  type        = string
  sensitive   = true
}

variable "ecs_service_desired_count" {
  type        = number
  sensitive   = true
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name

  tags = {
    Name        = var.ecs_cluster_name
    Environment = "production"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_name
  requires_compatibilities = ["EC2", "FARGATE"]
  network_mode          = "awsvpc"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "container"
      image      = "amazonlinux"
      cpu        = 10
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Name        = var.ecs_task_definition_name
    Environment = "production"
  }
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

  tags = {
    Name        = "ecs-task-execution"
    Environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_target_group_name
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  tags = {
    Name        = var.alb_target_group_name
    Environment = "production"
  }
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "ecs-vpc"
    Environment = "production"
  }
}

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_service_desired_count
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.this.id]
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = "DISABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = "container"
    container_port   = 80
  }

  tags = {
    Name        = var.ecs_service_name
    Environment = "production"
  }
}

resource "aws_subnet" "this" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.this.id
  availability_zone = "us-east-1a"

  tags = {
    Name        = "ecs-subnet"
    Environment = "production"
  }
}

resource "aws_security_group" "this" {
  name        = "ecs-service"
  description = "ECS service security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name        = "ecs-service"
    Environment = "production"
  }
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "alb_target_group_arn" {
  value = aws_alb_target_group.this.arn
}

output "ecs_service_id" {
  value = aws_ecs_service.this.id
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.this.id
}

output "security_group_id" {
  value = aws_security_group.this.id
}