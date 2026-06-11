# Configure the AWS Provider
provider "aws" {
  version = "~> 4.0"
  region  = var.aws_region
}

# Create a launch template
resource "aws_launch_template" "launch_template" {
  name          = var.launch_template_name
  instance_type = var.instance_type
  image_id      = var.ami_id
  key_name      = var.key_name
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = [aws_security_group.security_group.id]
  }
  user_data = var.user_data == null ? null : base64encode(file(var.user_data))
}

# Create a security group
resource "aws_security_group" "security_group" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = aws_vpc.vpc.id
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
}

# Create subnets
resource "aws_subnet" "subnet1" {
  cidr_block = var.subnet1_cidr_block
  vpc_id     = aws_vpc.vpc.id
  availability_zone = var.availability_zone1
}

resource "aws_subnet" "subnet2" {
  cidr_block = var.subnet2_cidr_block
  vpc_id     = aws_vpc.vpc.id
  availability_zone = var.availability_zone2
}

# Create an Auto Scaling group
resource "aws_autoscaling_group" "asg" {
  name                = var.asg_name
  vpc_zone_identifier = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}

# Create a target group
resource "aws_lb_target_group" "target_group" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = aws_vpc.vpc.id
}

# Create scaling policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = var.scale_up_policy_name
  policy_type           = "ScalingPolicy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_up_adjustment
  cooldown               = var.scale_up_cooldown
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = var.scale_down_policy_name
  policy_type           = "ScalingPolicy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_down_adjustment
  cooldown               = var.scale_down_cooldown
}

# Create CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  alarm_name          = var.cpu_alarm_high_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_alarm_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_high_period
  statistic           = "Average"
  threshold           = var.cpu_alarm_high_threshold
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name          = var.cpu_alarm_low_name
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_alarm_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_low_period
  statistic           = "Average"
  threshold           = var.cpu_alarm_low_threshold
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}