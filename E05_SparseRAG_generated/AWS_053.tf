# Define variables
variable "asg_name" {
  type        = string
  description = "Name of the Auto Scaling group"
}

variable "asg_instance_type" {
  type        = string
  description = "Instance type for the Auto Scaling group"
}

variable "asg_ami" {
  type        = string
  description = "AMI ID for the Auto Scaling group"
}

variable "asg_key_name" {
  type        = string
  description = "Key name for the Auto Scaling group"
}

variable "asg_public_ip" {
  type        = bool
  description = "Whether to associate a public IP address with the Auto Scaling group"
}

variable "security_group_id" {
  type        = string
  description = "ID of the security group for the Auto Scaling group"
}

variable "user_data" {
  type        = string
  description = "Path to the user data file for the Auto Scaling group"
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

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the Auto Scaling group"
}

variable "target_group_arns" {
  type        = list(string)
  description = "List of target group ARNs for the Auto Scaling group"
}

variable "launch_template_version" {
  type        = string
  description = "Version of the launch template"
}

# Launch template
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

# Auto Scaling group
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

# Scaling policies
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.asg_name}-scale-out"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.asg_name}-scale-in"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = -1
  cooldown               = 60
}

# CloudWatch metric alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.asg_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.asg_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
}