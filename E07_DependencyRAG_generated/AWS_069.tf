# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "ecs-fargate-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "ecs-fargate-subnet"
  }
}

# Create a security group for the ALB
resource "aws_security_group" "alb" {
  name        = "ecs-fargate-alb-sg"
  description = "ALB Security Group configuration"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow HTTP traffic"
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
  description = "ECS Security Group configuration"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow traffic from the ALB"
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

# Create an ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "ecs-fargate-cluster"

  tags = {
    Name = "ecs-fargate-cluster"
  }
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "this" {
  family                = "ecs-fargate-task"
  cpu                    = var.task_cpu
  memory                = var.task_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-fargate-container"
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

  tags = {
    Name = "ecs-fargate-task"
  }
}

# Create an IAM role for the ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name        = "ecs-fargate-task-execution"
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
    Name = "ecs-fargate-task-execution"
  }
}

# Create an IAM policy for the ECS task execution
resource "aws_iam_policy" "ecs_task_execution" {
  name        = "ecs-fargate-task-execution-policy"
  description = "ECS Task Execution Policy"

  policy      = jsonencode({
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

# Create an ALB
resource "aws_lb" "this" {
  name               = "ecs-fargate-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.this.id]

  tags = {
    Name = "ecs-fargate-alb"
  }
}

# Create an ALB target group
resource "aws_lb_target_group" "this" {
  name     = "ecs-fargate-target-group"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  tags = {
    Name = "ecs-fargate-target-group"
  }
}

# Create an ALB listener
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }

  tags = {
    Name = "ecs-fargate-listener"
  }
}

# Create an ECS service
resource "aws_ecs_service" "this" {
  name            = "ecs-fargate-service"
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = [aws_subnet.this.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "ecs-fargate-container"
    container_port   = var.container_port
  }

  tags = {
    Name = "ecs-fargate-service"
  }
}