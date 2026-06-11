provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
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

variable "vpc_id" {
  type        = string
  description = "ID of VPC"
}

variable "subnet_id" {
  type        = string
  description = "ID of subnet"
}

variable "key_name" {
  type        = string
  description = "Name of key pair"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of allowed CIDR blocks for ingress"
}

resource "aws_launch_template" "example" {
  name          = "example-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name        = "example-launch-template"
    Environment = "example"
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
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "example-security-group"
    Environment = "example"
  }
}

resource "aws_autoscaling_group" "example" {
  name                = "example-autoscaling-group"
  max_size            = 5
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.subnet_id
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tags = [
    {
      key                 = "Name"
      value               = "example-autoscaling-group"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "example"
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "example-scale-up-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = 1
  cooldown               = 60

  tags = {
    Name        = "example-scale-up-policy"
    Environment = "example"
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "example-scale-down-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = -1
  cooldown               = 60

  tags = {
    Name        = "example-scale-down-policy"
    Environment = "example"
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = "example-scale-up-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 50
  alarm_description         = "Alarm for scaling up"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scale_up.arn]
  insufficient_data_actions = []
  ok_actions                = []

  tags = {
    Name        = "example-scale-up-alarm"
    Environment = "example"
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name                = "example-scale-down-alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 30
  alarm_description         = "Alarm for scaling down"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scale_down.arn]
  insufficient_data_actions = []
  ok_actions                = []

  tags = {
    Name        = "example-scale-down-alarm"
    Environment = "example"
  }
}

output "launch_template_id" {
  value = aws_launch_template.example.id
}

output "security_group_id" {
  value = aws_security_group.example.id
}

output "autoscaling_group_id" {
  value = aws_autoscaling_group.example.id
}

output "scale_up_policy_arn" {
  value = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  value = aws_autoscaling_policy.scale_down.arn
}

output "scale_up_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.scale_up_alarm.arn
}

output "scale_down_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.scale_down_alarm.arn
}