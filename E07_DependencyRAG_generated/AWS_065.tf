provider "aws" {
  region = var.region
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_name
  cpu                    = var.ecs_task_definition_cpu
  memory                = var.ecs_task_definition_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name        = var.container_name
      image       = var.container_image
      cpu         = var.container_cpu
      memory      = var.container_memory
      essential   = true
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
  name        = var.ecs_task_execution_role_name
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

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = [aws_subnet.public.id, aws_subnet.private.id]
  security_groups = [aws_security_group.alb.id]
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

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = var.availability_zone
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = var.availability_zone
}

resource "aws_security_group" "alb" {
  name        = var.alb_security_group_name
  description = "ALB Security Group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_service_desired_count
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}

resource "aws_security_group" "ecs" {
  name        = var.ecs_security_group_name
  description = "ECS Security Group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "region" {
  type        = string
  default     = "us-west-2"
}

variable "ecs_cluster_name" {
  type        = string
  default     = "my-ecs-cluster"
}

variable "ecs_task_definition_name" {
  type        = string
  default     = "my-ecs-task-definition"
}

variable "ecs_task_definition_cpu" {
  type        = string
  default     = "256"
}

variable "ecs_task_definition_memory" {
  type        = string
  default     = "512"
}

variable "container_name" {
  type        = string
  default     = "my-container"
}

variable "container_image" {
  type        = string
  default     = "nginx:latest"
}

variable "container_cpu" {
  type        = string
  default     = "10"
}

variable "container_memory" {
  type        = string
  default     = "128"
}

variable "container_port" {
  type        = number
  default     = 80
}

variable "ecs_task_execution_role_name" {
  type        = string
  default     = "my-ecs-task-execution-role"
}

variable "alb_name" {
  type        = string
  default     = "my-alb"
}

variable "alb_target_group_name" {
  type        = string
  default     = "my-alb-target-group"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_block" {
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  type        = string
  default     = "us-west-2a"
}

variable "alb_security_group_name" {
  type        = string
  default     = "my-alb-security-group"
}

variable "ecs_service_name" {
  type        = string
  default     = "my-ecs-service"
}

variable "ecs_service_desired_count" {
  type        = number
  default     = 1
}

variable "ecs_security_group_name" {
  type        = string
  default     = "my-ecs-security-group"
}