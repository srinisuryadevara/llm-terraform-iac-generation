provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_family
  cpu                    = var.ecs_task_definition_cpu
  memory                 = var.ecs_task_definition_memory
  network_mode           = var.ecs_task_definition_network_mode
  requires_compatibilities = var.ecs_task_definition_requires_compatibilities
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = var.ecs_task_definition_container_name
      image      = var.ecs_task_definition_container_image
      cpu        = var.ecs_task_definition_container_cpu
      essential = true
      portMappings = [
        {
          containerPort = var.ecs_task_definition_container_port
          hostPort      = var.ecs_task_definition_container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecs_task_execution" {
  name        = var.ecs_task_execution_role_name
  description = var.ecs_task_execution_role_description

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

resource "aws_alb_target_group" "this" {
  name     = var.alb_target_group_name
  port     = var.alb_target_group_port
  protocol = var.alb_target_group_protocol
  vpc_id   = var.vpc_id
}

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_service_desired_count
  launch_type     = var.ecs_service_launch_type

  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = var.ecs_task_definition_container_name
    container_port    = var.ecs_task_definition_container_port
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}