provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
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

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of VPC security group IDs"
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
  vpc_security_group_ids = var.vpc_security_group_ids
}

resource "aws_autoscaling_group" "example" {
  name                = "example-autoscaling-group"
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = "subnet-12345678"
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "example-scale-up-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 60
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "example-scale-down-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = -1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 60
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "example-cpu-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "example-cpu-low-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "40"
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}