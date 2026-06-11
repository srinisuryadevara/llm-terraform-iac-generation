# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Define variables
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "asg_name" {
  type        = string
  description = "Auto Scaling Group Name"
}

variable "asg_instance_type" {
  type        = string
  description = "Instance Type for Auto Scaling Group"
}

variable "asg_ami" {
  type        = string
  description = "AMI ID for Auto Scaling Group"
}

variable "asg_key_name" {
  type        = string
  description = "Key Name for Auto Scaling Group"
}

variable "security_group_id" {
  type        = string
  description = "Security Group ID for Auto Scaling Group"
}

variable "asg_public_ip" {
  type        = bool
  description = "Associate Public IP with Auto Scaling Group"
}

variable "user_data" {
  type        = string
  description = "User Data for Auto Scaling Group"
}

variable "min_size" {
  type        = number
  description = "Minimum Size for Auto Scaling Group"
}

variable "max_size" {
  type        = number
  description = "Maximum Size for Auto Scaling Group"
}

variable "desired_capacity" {
  type        = number
  description = "Desired Capacity for Auto Scaling Group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public Subnet IDs for Auto Scaling Group"
}

variable "target_group_arns" {
  type        = list(string)
  description = "Target Group ARNs for Auto Scaling Group"
}

variable "launch_template_version" {
  type        = string
  description = "Launch Template Version"
}

# Create Launch Template
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

# Create Auto Scaling Group
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

# Create Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = -1
  cooldown               = 60
}

# Create CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-low"
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