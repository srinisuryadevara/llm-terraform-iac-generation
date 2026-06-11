# Configure the AWS Provider
terraform {
  required_version = "1.3.9"
}

provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

# Define variables
variable "region" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "ami_id" {
  type        = string
  sensitive   = true
}

variable "instance_type" {
  type        = string
  sensitive   = true
}

variable "key_name" {
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  type        = string
  sensitive   = true
}

variable "public_subnet_ids" {
  type        = list(string)
  sensitive   = true
}

variable "min_size" {
  type        = number
  sensitive   = true
}

variable "max_size" {
  type        = number
  sensitive   = true
}

variable "desired_capacity" {
  type        = number
  sensitive   = true
}

variable "launch_template_version" {
  type        = string
  sensitive   = true
}

variable "scaling_policy_up" {
  type        = string
  sensitive   = true
}

variable "scaling_policy_down" {
  type        = string
  sensitive   = true
}

# Get VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Get subnets
data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.main.id
}

# Launch template
resource "aws_launch_template" "launch_template" {
  name          = "launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "auto-scaling-group"
  vpc_zone_identifier = var.public_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = var.launch_template_version
  }
}

# Scaling policy up
resource "aws_autoscaling_policy" "scaling_policy_up" {
  name                   = "scaling-policy-up"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
}

# Scaling policy down
resource "aws_autoscaling_policy" "scaling_policy_down" {
  name                   = "scaling-policy-down"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
}

# CloudWatch metric alarm up
resource "aws_cloudwatch_metric_alarm" "alarm_up" {
  alarm_name                = "alarm-up"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 50
  alarm_description         = "Alarm when CPU utilization is high"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scaling_policy_up.arn]
  insufficient_data_actions = []
  ok_actions                = []
}

# CloudWatch metric alarm down
resource "aws_cloudwatch_metric_alarm" "alarm_down" {
  alarm_name                = "alarm-down"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 30
  alarm_description         = "Alarm when CPU utilization is low"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scaling_policy_down.arn]
  insufficient_data_actions = []
  ok_actions                = []
}