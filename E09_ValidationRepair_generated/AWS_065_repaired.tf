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

variable "alb_listener_port" {
  type        = number
  description = "ALB Listener Port"
}

variable "alb_target_group_name" {
  type        = string
  description = "ALB Target Group Name"
}

variable "alb_target_group_port" {
  type        = number
  description = "ALB Target Group Port"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "docker_image_url" {
  type        = string
  description = "Docker Image URL"
}

variable "docker_container_port" {
  type        = number
  description = "Docker Container Port"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR Blocks"
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name

  tags = {
    Name        = var.ecs_cluster_name
    Environment = "production"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_family
  cpu                   = var.ecs_task_definition_cpu
  memory                = var.ecs_task_definition_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn   = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "app"
      image      = var.docker_image_url
      cpu        = var.ecs_task_definition_cpu
      portMappings = [
        {
          containerPort = var.docker_container_port
          hostPort      = var.docker_container_port
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Name        = var.ecs_task_definition_family
    Environment = "production"
  }
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

  tags = {
    Name        = "ecs-task-execution"
    Environment = "production"
  }
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
    security_groups  = [aws_security_group.ecs.id]
    subnets          = var.subnet_ids
    assign_public_ip = "DISABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = "app"
    container_port   = var.docker_container_port
  }

  depends_on = [aws_alb_listener.this]

  tags = {
    Name        = var.ecs_service_name
    Environment = "production"
  }
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name        = var.alb_name
    Environment = "production"
  }
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_target_group_name
  port        = var.alb_target_group_port
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  tags = {
    Name        = var.alb_target_group_name
    Environment = "production"
  }
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.alb_listener_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID"

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }

  tags = {
    Name        = "alb-listener"
    Environment = "production"
  }
}

resource "aws_security_group" "ecs" {
  name        = "ecs-sg"
  description = "ECS Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.docker_container_port
    to_port     = var.docker_container_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ecs-sg"
    Environment = "production"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg"
    Environment = "production"
  }
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "ecs_service_id" {
  value = aws_ecs_service.this.id
}

output "alb_id" {
  value = aws_alb.this.id
}

output "alb_dns_name" {
  value = aws_alb.this.dns_name
}

output "alb_target_group_arn" {
  value = aws_alb_target_group.this.arn
}