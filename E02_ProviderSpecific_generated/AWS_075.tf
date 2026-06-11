provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "ami_id" {
  type        = string
  description = "ID of AMI"
}

variable "instance_type" {
  type        = string
  description = "Type of instance"
}

variable "key_name" {
  type        = string
  description = "Name of key pair"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs"
}

variable "min_size" {
  type        = number
  description = "Minimum size of Auto Scaling group"
}

variable "max_size" {
  type        = number
  description = "Maximum size of Auto Scaling group"
}

variable "desired_capacity" {
  type        = number
  description = "Desired capacity of Auto Scaling group"
}

resource "aws_launch_template" "example" {
  name          = "example-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = var.security_group_ids
}

resource "aws_autoscaling_group" "example" {
  name                = "example-autoscaling-group"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity   = var.desired_capacity
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "example-scale-up-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown               = 60
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "example-scale-down-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = -1
  adjustment_type       = "ChangeInCapacity"
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "example-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "example-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}