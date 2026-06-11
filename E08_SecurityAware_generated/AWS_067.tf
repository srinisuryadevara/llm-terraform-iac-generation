provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR Block"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR Block"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR Block"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
}

variable "ami_id" {
  type        = string
  description = "EC2 AMI ID"
}

variable "key_pair_name" {
  type        = string
  description = "EC2 Key Pair Name"
}

variable "min_size" {
  type        = number
  description = "Auto Scaling Group Minimum Size"
}

variable "max_size" {
  type        = number
  description = "Auto Scaling Group Maximum Size"
}

variable "desired_size" {
  type        = number
  description = "Auto Scaling Group Desired Size"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "this" {
  cidr_block = var.subnet_cidr
  vpc_id     = aws_vpc.this.id
  availability_zone = "us-west-2a"
  tags = {
    Name        = "${var.project}-${var.environment}-subnet"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-sg"
  description = "Security Group for EC2 Instances"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-sg"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role" "this" {
  name        = "${var.project}-${var.environment}-ec2-role"
  description = "IAM Role for EC2 Instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-ec2-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.project}-${var.environment}-ec2-policy"
  description = "IAM Policy for EC2 Instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-ec2-policy"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_launch_template" "this" {
  name          = "${var.project}-${var.environment}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile {
    name = aws_iam_role.this.name
  }

  tags = {
    Name        = "${var.project}-${var.environment}-lt"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.project}-${var.environment}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_size
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  vpc_zone_identifier       = aws_subnet.this.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.project}-${var.environment}-asg"
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
    }
  ]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project}-${var.environment}-scale-up"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = 1
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project}-${var.environment}-scale-down"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = -1
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = "${var.project}-${var.environment}-scale-up-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 50
  alarm_description         = "Scale up when CPU utilization is high"
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
  period                    = 60
  statistic                 = "Average"
  threshold                 = 20
  alarm_description         = "Scale down when CPU utilization is low"
  actions_enabled           = true
  alarm_actions             = [aws_autoscaling_policy.scale_down.arn]
  insufficient_data_actions = []
  ok_actions                = []
}