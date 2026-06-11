# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "ecs-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "ecs_subnet" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "ecs-subnet"
  }
}

# Create a security group for the ECS service
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS service"
  vpc_id      = aws_vpc.ecs_vpc.id

  # Allow inbound traffic on port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                = "ecs-task-definition"
  cpu                   = var.task_cpu
  memory                = var.task_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-container"
      image      = var.container_image
      cpu        = var.container_cpu
      memory    = var.container_memory
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

# Create an IAM role for the ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name        = "ecs-task-execution-role"
  description = "IAM role for ECS task execution"

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

# Create an IAM policy for the ECS task execution
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs-task-execution-policy"
  description = "IAM policy for ECS task execution"

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
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

# Create an ALB target group
resource "aws_alb_target_group" "ecs_alb_target_group" {
  name        = "ecs-alb-target-group"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"
}

# Create an ALB listener
resource "aws_alb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_alb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs_alb_target_group.arn
    type             = "forward"
  }
}

# Create an ALB
resource "aws_alb" "ecs_alb" {
  name            = "ecs-alb"
  subnets         = [aws_subnet.ecs_subnet.id]
  security_groups = [aws_security_group.ecs_sg.id]
}

# Create an ECS service
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.name
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.desired_count
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.ecs_subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_alb_target_group.arn
    container_name   = "ecs-container"
    container_port   = var.container_port
  }
}

variable "region" {
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  type        = string
  default     = "us-west-2a"
}

variable "task_cpu" {
  type        = string
  default     = "256"
}

variable "task_memory" {
  type        = string
  default     = "512"
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
  default     = "50"
}

variable "container_port" {
  type        = number
  default     = 80
}

variable "desired_count" {
  type        = number
  default     = 1
}