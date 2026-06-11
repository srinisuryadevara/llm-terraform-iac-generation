# Configure the AWS Provider
provider "aws" {
  version = "~> 4.0"
  region  = var.region
}

# Create a launch template
resource "aws_launch_template" "example" {
  name = var.launch_template_name

  instance_type = var.instance_type
  image_id      = var.image_id
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
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an Auto Scaling group
resource "aws_autoscaling_group" "example" {
  name                = var.autoscaling_group_name
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

# Create a target group
resource "aws_lb_target_group" "example" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id
}

# Create a target group attachment
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.example.id
  alb_target_group_arn   = aws_lb_target_group.example.arn
}

# Create a scaling policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = var.scale_up_policy_name
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_up_adjustment
  cooldown               = var.scale_up_cooldown
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = var.scale_down_policy_name
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_down_adjustment
  cooldown               = var.scale_down_cooldown
}

# Create a CloudWatch metric alarm
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
  type        = string
  description = "AWS region"
}

variable "launch_template_name" {
  type        = string
  description = "Launch template name"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "image_id" {
  type        = string
  description = "Image ID"
}

variable "key_name" {
  type        = string
  description = "Key name"
}

variable "associate_public_ip" {
  type        = bool
  description = "Associate public IP"
}

variable "security_group_name" {
  type        = string
  description = "Security group name"
}

variable "security_group_description" {
  type        = string
  description = "Security group description"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "autoscaling_group_name" {
  type        = string
  description = "Auto Scaling group name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "min_size" {
  type        = number
  description = "Minimum size"
}

variable "max_size" {
  type        = number
  description = "Maximum size"
}

variable "desired_capacity" {
  type        = number
  description = "Desired capacity"
}

variable "target_group_name" {
  type        = string
  description = "Target group name"
}

variable "target_group_port" {
  type        = number
  description = "Target group port"
}

variable "target_group_protocol" {
  type        = string
  description = "Target group protocol"
}

variable "scale_up_policy_name" {
  type        = string
  description = "Scale up policy name"
}

variable "scale_up_adjustment" {
  type        = number
  description = "Scale up adjustment"
}

variable "scale_up_cooldown" {
  type        = number
  description = "Scale up cooldown"
}

variable "scale_down_policy_name" {
  type        = string
  description = "Scale down policy name"
}

variable "scale_down_adjustment" {
  type        = number
  description = "Scale down adjustment"
}

variable "scale_down_cooldown" {
  type        = number
  description = "Scale down cooldown"
}

variable "scale_up_alarm_name" {
  type        = string
  description = "Scale up alarm name"
}

variable "scale_up_comparison_operator" {
  type        = string
  description = "Scale up comparison operator"
}

variable "scale_up_evaluation_periods" {
  type        = number
  description = "Scale up evaluation periods"
}

variable "scale_up_metric_name" {
  type        = string
  description = "Scale up metric name"
}

variable "scale_up_namespace" {
  type        = string
  description = "Scale up namespace"
}

variable "scale_up_period" {
  type        = number
  description = "Scale up period"
}

variable "scale_up_statistic" {
  type        = string
  description = "Scale up statistic"
}

variable "scale_up_threshold" {
  type        = number
  description = "Scale up threshold"
}

variable "scale_down_alarm_name" {
  type        = string
  description = "Scale down alarm name"
}

variable "scale_down_comparison_operator" {
  type        = string
  description = "Scale down comparison operator"
}

variable "scale_down_evaluation_periods" {
  type        = number
  description = "Scale down evaluation periods"
}

variable "scale_down_metric_name" {
  type        = string
  description = "Scale down metric name"
}

variable "scale_down_namespace" {
  type        = string
  description = "Scale down namespace"
}

variable "scale_down_period" {
  type        = number
  description = "Scale down period"
}

variable "scale_down_statistic" {
  type        = string
  description = "Scale down statistic"
}

variable "scale_down_threshold" {
  type        = number
  description = "Scale down threshold"
}

variable "user_data" {
  type        = string
  description = "User data"
}