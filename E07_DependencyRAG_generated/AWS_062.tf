variable "asg_name" {
  type = string
}

variable "asg_instance_type" {
  type = string
}

variable "asg_ami" {
  type = string
}

variable "asg_key_name" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "asg_public_ip" {
  type = bool
}

variable "user_data" {
  type    = string
  default = null
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "target_group_arns" {
  type = list(string)
}

variable "launch_template_version" {
  type = string
}

variable "scale_up_policy_name" {
  type = string
}

variable "scale_down_policy_name" {
  type = string
}

variable "scale_up_adjustment" {
  type = number
}

variable "scale_down_adjustment" {
  type = number
}

variable "scale_up_cooldown" {
  type = number
}

variable "scale_down_cooldown" {
  type = number
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_launch_template" "launch_template" {
  instance_type = var.asg_instance_type
  image_id      = var.asg_ami
  key_name      = var.asg_key_name
  network_interfaces {
    associate_public_ip_address = var.asg_public_ip
    security_groups             = [var.security_group_id]
  }
  user_data = var.user_data == null ? null : base64encode(file(var.user_data))
}

resource "aws_autoscaling_group" "asg" {
  name                = var.asg_name
  target_group_arns   = var.target_group_arns
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.public_subnet_ids
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = var.launch_template_version
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = var.scale_up_policy_name
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = var.scale_up_adjustment
  cooldown               = var.scale_up_cooldown
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = var.scale_down_policy_name
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = var.scale_down_adjustment
  cooldown               = var.scale_down_cooldown
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]
  ok_actions          = []
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]
  ok_actions          = []
  insufficient_data_actions = []
}