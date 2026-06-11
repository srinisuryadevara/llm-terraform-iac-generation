provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH allowed CIDR"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "key_name" {
  type        = string
  description = "Key pair name"
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
  name          = "${var.project}-${var.environment}-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name        = "${var.project}-${var.environment}-launch-template"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "example" {
  name        = "${var.project}-${var.environment}-security-group"
  description = "Security group for the Auto Scaling group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-security-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_autoscaling_group" "example" {
  name                = "${var.project}-${var.environment}-autoscaling-group"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.project}-${var.environment}-autoscaling-group"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = var.environment
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project}-${var.environment}-scale-up-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project}-${var.environment}-scale-down-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = "${var.project}-${var.environment}-scale-up-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 50
  alarm_description         = "Scale up alarm"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scale_up.arn]
  insufficient_data_actions = []
  ok_actions                = []
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name                = "${var.project}-${var.environment}-scale-down-alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 20
  alarm_description         = "Scale down alarm"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scale_down.arn]
  insufficient_data_actions = []
  ok_actions                = []
}