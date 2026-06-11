# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "ecs-fargate-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = "us-west-2a"

  tags = {
    Name = "ecs-fargate-public-subnet"
  }
}

# Create a security group for the ALB
resource "aws_security_group" "alb" {
  name        = "ecs-fargate-alb-sg"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.default.id

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

  tags = {
    Name = "ecs-fargate-alb-sg"
  }
}

# Create a security group for the ECS task
resource "aws_security_group" "ecs" {
  name        = "ecs-fargate-ecs-sg"
  description = "Security group for the ECS task"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-fargate-ecs-sg"
  }
}

# Create an ALB
resource "aws_alb" "default" {
  name            = "ecs-fargate-alb"
  subnets         = [aws_subnet.public.id]
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = "ecs-fargate-alb"
  }
}

# Create a target group
resource "aws_alb_target_group" "default" {
  name     = "ecs-fargate-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    path                = "/"
    interval            = 10
  }

  tags = {
    Name = "ecs-fargate-tg"
  }
}

# Create an ALB listener
resource "aws_alb_listener" "default" {
  load_balancer_arn = aws_alb.default.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.default.arn
    type             = "forward"
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "default" {
  name = "ecs-fargate-cluster"

  tags = {
    Name = "ecs-fargate-cluster"
  }
}

# Create a task definition
resource "aws_ecs_task_definition" "default" {
  family                = "ecs-fargate-task"
  cpu                    = var.cpu
  memory                = var.memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-fargate-container"
      image      = var.container_image
      cpu        = var.cpu
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
    Name = "ecs-fargate-task"
  }
}

# Create an IAM role for the ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name        = "ecs-fargate-task-execution"
  description = "IAM role for the ECS task execution"

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
    Name = "ecs-fargate-task-execution"
  }
}

# Create an IAM policy for the ECS task execution
resource "aws_iam_policy" "ecs_task_execution" {
  name        = "ecs-fargate-task-execution-policy"
  description = "IAM policy for the ECS task execution"

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
    Name = "ecs-fargate-task-execution-policy"
  }
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

# Create an ECS service
resource "aws_ecs_service" "default" {
  name            = "ecs-fargate-service"
  cluster         = aws_ecs_cluster.default.name
  task_definition = aws_ecs_task_definition.default.arn
  desired_count   = var.desired_count
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = [aws_subnet.public.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.default.arn
    container_name   = "ecs-fargate-container"
    container_port   = 80
  }

  tags = {
    Name = "ecs-fargate-service"
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

variable "public_subnet_cidr_block" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "cpu" {
  type        = string
  default     = "256"
}

variable "memory" {
  type        = string
  default     = "512"
}

variable "container_image" {
  type        = string
  default     = "nginx:latest"
}

variable "desired_count" {
  type        = number
  default     = 1
}