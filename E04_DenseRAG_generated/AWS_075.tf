# Configure the AWS Provider
terraform {
  required_version = "1.3.9"
}

provider "aws" {
  version = "~> 4.0"
  region  = var.aws_region
}

# Define variables
variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "asg_name" {
  type        = string
}

variable "asg_instance_type" {
  type        = string
}

variable "asg_ami" {
  type        = string
}

variable "asg_key_name" {
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  type        = string
}

variable "user_data" {
  type        = string
  default     = null
}

variable "min_size" {
  type        = number
}

variable "max_size" {
  type        = number
}

variable "desired_capacity" {
  type        = number
}

variable "public_subnet_ids" {
  type        = list(string)
}

variable "launch_template_version" {
  type        = string
  default     = "$Latest"
}

variable "scaling_policy_up" {
  type        = string
}

variable "scaling_policy_down" {
  type        = string
}

# Launch template
resource "aws_launch_template" "launch_template" {
  instance_type = var.asg_instance_type
  image_id      = var.asg_ami
  key_name      = var.asg_key_name
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }
  user_data = var.user_data == null ? null : base64encode(file(var.user_data))
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = var.asg_name
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.public_subnet_ids
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = var.launch_template_version
  }
}

# Scaling policy up
resource "aws_autoscaling_policy" "scaling_policy_up" {
  name                   = var.scaling_policy_up
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
}

# Scaling policy down
resource "aws_autoscaling_policy" "scaling_policy_down" {
  name                   = var.scaling_policy_down
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