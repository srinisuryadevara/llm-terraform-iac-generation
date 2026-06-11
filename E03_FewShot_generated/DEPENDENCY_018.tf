provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "ecs_task_definition_name" {
  type        = string
  description = "ECS task definition name"
}

variable "alb_target_group_name" {
  type        = string
  description = "ALB target group name"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name"
}

variable "ecs_service_desired_count" {
  type        = number
  description = "ECS service desired count"
}

data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_name
}

data "aws_ecs_task_definition" "this" {
  task_definition = var.ecs_task_definition_name
}

data "aws_lb_target_group" "this" {
  name = var.alb_target_group_name
}

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = data.aws_ecs_cluster.this.arn
  task_definition = data.aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_service_desired_count
  launch_type      = "EC2"

  load_balancer {
    target_group_arn = data.aws_lb_target_group.this.arn
    container_name   = "container-name"
    container_port   = 80
  }
}