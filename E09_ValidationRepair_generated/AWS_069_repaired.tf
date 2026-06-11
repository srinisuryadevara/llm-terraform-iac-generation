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

variable "ecs_task_definition_container_name" {
  type        = string
  description = "ECS Task Definition Container Name"
}

variable "ecs_task_definition_container_image" {
  type        = string
  description = "ECS Task Definition Container Image"
}

variable "ecs_task_definition_container_port" {
  type        = number
  description = "ECS Task Definition Container Port"
}

variable "alb_name" {
  type        = string
  description = "ALB Name"
}

variable "alb_subnets" {
  type        = list(string)
  description = "ALB Subnets"
}

variable "alb_security_groups" {
  type        = list(string)
  description = "ALB Security Groups"
}

variable "alb_target_group_name" {
  type        = string
  description = "ALB Target Group Name"
}

variable "alb_target_group_port" {
  type        = number
  description = "ALB Target Group Port"
}

variable "alb_listener_port" {
  type        = number
  description = "ALB Listener Port"
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
  cpu                    = var.ecs_task_definition_cpu
  memory                = var.ecs_task_definition_memory
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name        = var.ecs_task_definition_container_name
      image       = var.ecs_task_definition_container_image
      cpu         = var.ecs_task_definition_cpu
      essential   = true
      portMappings = [
        {
          containerPort = var.ecs_task_definition_container_port
          hostPort      = var.ecs_task_definition_container_port
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

resource "aws_iam_policy" "ecs_task_execution" {
  name        = "ecs-task-execution-policy"
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
    Name        = "ecs-task-execution-policy"
    Environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.alb_subnets
  security_groups = var.alb_security_groups
  tags = {
    Name        = var.alb_name
    Environment = "production"
  }
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_target_group_name
  port        = var.alb_target_group_port
  protocol    = "HTTP"
  vpc_id      = aws_alb.this.vpc_id
  target_type = "ip"
  tags = {
    Name        = var.alb_target_group_name
    Environment = "production"
  }
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_ecs_service" "this" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = var.alb_security_groups
    subnets          = var.alb_subnets
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = var.ecs_task_definition_container_name
    container_port   = var.ecs_task_definition_container_port
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

output "alb_dns_name" {
  value = aws_alb.this.dns_name
}

output "alb_target_group_arn" {
  value = aws_alb_target_group.this.arn
}

output "ecs_service_id" {
  value = aws_ecs_service.this.id
}