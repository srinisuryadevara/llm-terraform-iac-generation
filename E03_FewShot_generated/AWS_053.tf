provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the launch template"
}

variable "ami_id" {
  type        = string
  description = "ID of the AMI for the launch template"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC for the launch template"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs of the subnets for the launch template"
}

variable "key_name" {
  type        = string
  description = "Name of the key pair for the launch template"
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
  vpc_security_group_ids = [
    aws_security_group.example.id
  ]
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.example.id]
    subnet_id                   = var.subnet_ids[0]
  }
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "example" {
  name                = "example-autoscaling-group"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "example-scale-out-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = 1
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "example-scale-in-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = -1
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "example-high-cpu-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 50
  alarm_description         = "Alarm when CPU utilization is high"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scale_out.arn]
  insufficient_data_actions = []
  ok_actions                = []
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name                = "example-low-cpu-alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 20
  alarm_description         = "Alarm when CPU utilization is low"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scale_in.arn]
  insufficient_data_actions = []
  ok_actions                = []
}