# Configure the AWS Provider
provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

# Create a launch template
resource "aws_launch_template" "example" {
  name          = var.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = [aws_security_group.example.id]
  }
  user_data = var.user_data == null ? null : base64encode(file(var.user_data))
}

# Create a security group
resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = aws_vpc.example.id
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
}

# Create subnets
resource "aws_subnet" "example" {
  count             = var.num_subnets
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  vpc_id            = aws_vpc.example.id
}

# Create an Auto Scaling group
resource "aws_autoscaling_group" "example" {
  name                = var.asg_name
  vpc_zone_identifier = [for subnet in aws_subnet.example : subnet.id]
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

# Create scaling policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = var.scale_up_policy_name
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = var.scale_up_adjustment
  cooldown               = var.scale_up_cooldown
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = var.scale_down_policy_name
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  scaling_adjustment     = var.scale_down_adjustment
  cooldown               = var.scale_down_cooldown
}

# Create CloudWatch alarms for scaling
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = var.scale_up_alarm_name
  comparison_operator = var.scale_up_comparison_operator
  evaluation_periods  = var.scale_up_evaluation_periods
  metric_name         = var.scale_up_metric_name
  namespace           = var.scale_up_namespace
  period              = var.scale_up_period
  statistic           = var.scale_up_statistic
  threshold           = var.scale_up_threshold
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = var.scale_down_alarm_name
  comparison_operator = var.scale_down_comparison_operator
  evaluation_periods  = var.scale_down_evaluation_periods
  metric_name         = var.scale_down_metric_name
  namespace           = var.scale_down_namespace
  period              = var.scale_down_period
  statistic           = var.scale_down_statistic
  threshold           = var.scale_down_threshold
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}

variable "region" {
  type = string
}

variable "launch_template_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "associate_public_ip" {
  type = bool
}

variable "security_group_name" {
  type = string
}

variable "security_group_description" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "num_subnets" {
  type = number
}

variable "availability_zones" {
  type = list(string)
}

variable "asg_name" {
  type = string
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

variable "scale_up_policy_name" {
  type = string
}

variable "scale_up_adjustment" {
  type = number
}

variable "scale_up_cooldown" {
  type = number
}

variable "scale_down_policy_name" {
  type = string
}

variable "scale_down_adjustment" {
  type = number
}

variable "scale_down_cooldown" {
  type = number
}

variable "scale_up_alarm_name" {
  type = string
}

variable "scale_up_comparison_operator" {
  type = string
}

variable "scale_up_evaluation_periods" {
  type = number
}

variable "scale_up_metric_name" {
  type = string
}

variable "scale_up_namespace" {
  type = string
}

variable "scale_up_period" {
  type = number
}

variable "scale_up_statistic" {
  type = string
}

variable "scale_up_threshold" {
  type = number
}

variable "scale_down_alarm_name" {
  type = string
}

variable "scale_down_comparison_operator" {
  type = string
}

variable "scale_down_evaluation_periods" {
  type = number
}

variable "scale_down_metric_name" {
  type = string
}

variable "scale_down_namespace" {
  type = string
}

variable "scale_down_period" {
  type = number
}

variable "scale_down_statistic" {
  type = string
}

variable "scale_down_threshold" {
  type = number
}

variable "user_data" {
  type    = string
  default = null
}