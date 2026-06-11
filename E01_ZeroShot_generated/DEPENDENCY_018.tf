provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "ecs_cluster_name" {
  type        = string
  sensitive   = false
}

variable "ecs_task_definition_arn" {
  type        = string
  sensitive   = false
}

variable "alb_target_group_arn" {
  type        = string
  sensitive   = false
}

variable "ecs_service_name" {
  type        = string
  sensitive   = false
}

variable "ecs_service_desired_count" {
  type        = number
  sensitive   = false
}

data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_name
}

data "aws_ecs_task_definition" "this" {
  task_definition_arn = var.ecs_task_definition_arn
}

data "aws_lb_target_group" "this" {
  arn = var.alb_target_group_arn
}

resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = data.aws_ecs_cluster.this.arn
  task_definition = data.aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_service_desired_count

  load_balancer {
    target_group_arn = data.aws_lb_target_group.this.arn
    container_name   = data.aws_ecs_task_definition.this.container_definitions[0].name
    container_port   = data.aws_ecs_task_definition.this.container_definitions[0].portMappings[0].containerPort
  }
}