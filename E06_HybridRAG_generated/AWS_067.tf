# Configure the AWS Provider
provider "aws" {
  region = local.region
}

# Define variables
variable "asg_name" {
  type        = string
  description = "The name of the Auto Scaling group"
}

variable "asg_instance_type" {
  type        = string
  description = "The instance type for the Auto Scaling group"
}

variable "asg_ami" {
  type        = string
  description = "The ID of the AMI for the Auto Scaling group"
}

variable "asg_key_name" {
  type        = string
  description = "The name of the key pair for the Auto Scaling group"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group for the Auto Scaling group"
}

variable "asg_public_ip" {
  type        = bool
  description = "Whether to associate a public IP address with the Auto Scaling group"
}

variable "user_data" {
  type        = string
  description = "The user data for the Auto Scaling group"
}

variable "min_size" {
  type        = number
  description = "The minimum size of the Auto Scaling group"
}

variable "max_size" {
  type        = number
  description = "The maximum size of the Auto Scaling group"
}

variable "desired_capacity" {
  type        = number
  description = "The desired capacity of the Auto Scaling group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets for the Auto Scaling group"
}

variable "launch_template_version" {
  type        = string
  description = "The version of the launch template"
}

variable "target_group_arns" {
  type        = list(string)
  description = "The ARNs of the target groups for the Auto Scaling group"
}

# Define the launch template
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

# Define the Auto Scaling group
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

# Define the scaling policies
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

# Define the CloudWatch metrics
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_2" {
  alarm_name          = "cpu-alarm-2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}