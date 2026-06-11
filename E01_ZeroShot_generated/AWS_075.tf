provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "ami_id" {
  type        = string
  description = "ID of AMI to use for the launch template"
}

variable "instance_type" {
  type        = string
  description = "Type of instance to use for the launch template"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC to use for the launch template"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs of subnets to use for the launch template"
}

variable "key_name" {
  type        = string
  description = "Name of key pair to use for the launch template"
}

variable "min_size" {
  type        = number
  description = "Minimum size of the Auto Scaling group"
}

variable "max_size" {
  type        = number
  description = "Maximum size of the Auto Scaling group"
}

variable "desired_capacity" {
  type        = number
  description = "Desired capacity of the Auto Scaling group"
}

resource "aws_launch_template" "example" {
  name          = "example-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Example security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
  vpc_zone_identifier = var.subnet_ids
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "example-scale-up-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  adjustment_type       = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "example-scale-down-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  adjustment_type       = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "example-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
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
  period              = 60
  statistic           = "Average"
  threshold           = 30
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}