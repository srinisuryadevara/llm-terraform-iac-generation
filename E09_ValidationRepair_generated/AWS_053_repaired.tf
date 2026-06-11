provider "aws" {
  region = var.region
}

variable "region" {
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
  description = "Name of the key pair to use for the launch template"
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

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR blocks for security group ingress"
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

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "example-security-group"
    Environment = "example"
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

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "example-cpu-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  ok_actions          = [aws_autoscaling_policy.scale_down.arn]
  insufficient_data_actions = []

  tags = {
    Name        = "example-cpu-high-alarm"
    Environment = "example"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "example-cpu-low-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  ok_actions          = [aws_autoscaling_policy.scale_up.arn]
  insufficient_data_actions = []

  tags = {
    Name        = "example-cpu-low-alarm"
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

output "cpu_high_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "cpu_low_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.cpu_low.arn
}