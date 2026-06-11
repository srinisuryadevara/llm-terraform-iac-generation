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
  description = "ECS Security Group configuration"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "Allow inbound traffic from the ALB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

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

# Create a security group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "ALB Security Group configuration"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "Allow inbound traffic from the internet"
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

  tags = {
    Name = "alb-sg"
  }
}

# Create an ALB
resource "aws_alb" "ecs_alb" {
  name            = "ecs-alb"
  subnets         = [aws_subnet.ecs_subnet.id]
  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name = "ecs-alb"
  }
}

# Create an ALB target group
resource "aws_alb_target_group" "ecs_tg" {
  name     = "ecs-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ecs_vpc.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = "traffic-port"
  }

  tags = {
    Name = "ecs-tg"
  }
}

# Create an ALB listener
resource "aws_alb_listener" "ecs_listener" {
  load_balancer_arn = aws_alb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs_tg.arn
    type             = "forward"
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"

  tags = {
    Name = "ecs-cluster"
  }
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "ecs_task" {
  family                = "ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode          = "awsvpc"
  cpu                   = var.task_cpu
  memory                = var.task_memory
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-container"
      image      = var.container_image
      cpu        = var.container_cpu
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
    Name = "ecs-task"
  }
}

# Create an IAM role for the ECS task execution
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
    Name = "ecs-task-execution"
  }
}

# Create an IAM policy for the ECS task execution
resource "aws_iam_policy" "ecs_task_execution" {
  name        = "ecs-task-execution"
  description = "ECS Task Execution Policy"

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

  tags = {
    Name = "ecs-task-execution"
  }
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

# Create an ECS service
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.name
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets          = [aws_subnet.ecs_subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_tg.arn
    container_name   = "ecs-container"
    container_port   = 80
  }

  tags = {
    Name = "ecs-service"
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

variable "desired_count" {
  type        = number
  default     = 1
}