provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "ami_id" {
  type        = string
  sensitive   = true
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  type        = list(string)
  sensitive   = true
}

variable "key_name" {
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
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
  vpc_zone_identifier = var.subnet_ids
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
    }
  ]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "example-scale-up-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = 1
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"

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
  adjustment_type        = "ChangeInCapacity"

  tags = {
    Name        = "example-scale-down-policy"
    Environment = "example"
  }
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
  ok_actions          = []
  insufficient_data_actions = []

  tags = {
    Name        = "example-scale-up-alarm"
    Environment = "example"
  }
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
  ok_actions          = []
  insufficient_data_actions = []

  tags = {
    Name        = "example-scale-down-alarm"
    Environment = "example"
  }
}

output "launch_template_id" {
  value       = aws_launch_template.example.id
  description = "The ID of the launch template"
}

output "security_group_id" {
  value       = aws_security_group.example.id
  description = "The ID of the security group"
}

output "autoscaling_group_id" {
  value       = aws_autoscaling_group.example.id
  description = "The ID of the autoscaling group"
}

output "scale_up_policy_arn" {
  value       = aws_autoscaling_policy.scale_up.arn
  description = "The ARN of the scale up policy"
}

output "scale_down_policy_arn" {
  value       = aws_autoscaling_policy.scale_down.arn
  description = "The ARN of the scale down policy"
}

output "scale_up_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.scale_up_alarm.arn
  description = "The ARN of the scale up alarm"
}

output "scale_down_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.scale_down_alarm.arn
  description = "The ARN of the scale down alarm"
}