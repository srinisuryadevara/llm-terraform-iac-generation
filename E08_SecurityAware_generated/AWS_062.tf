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
  description = "VPC CIDR"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Access CIDR"
}

variable "instance_type" {
  type        = string
  description = "Instance Type"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "key_name" {
  type        = string
  description = "Key Name"
}

variable "min_size" {
  type        = number
  description = "Minimum Size"
}

variable "max_size" {
  type        = number
  description = "Maximum Size"
}

variable "desired_capacity" {
  type        = number
  description = "Desired Capacity"
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
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, 1)
  availability_zone = "${var.region}a"

  tags = {
    Name        = "${var.project}-${var.environment}-subnet"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      var.ssh_cidr
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-security-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role" "this" {
  name        = "${var.project}-${var.environment}-role"
  description = "Role for Auto Scaling group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.project}-${var.environment}-policy"
  description = "Policy for Auto Scaling group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*",
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-policy"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_launch_template" "this" {
  name          = "${var.project}-${var.environment}-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]

  iam_instance_profile {
    name = aws_iam_role.this.name
  }

  tags = {
    Name        = "${var.project}-${var.environment}-launch-template"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.project}-${var.environment}-autoscaling-group"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = aws_subnet.this.id
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.project}-${var.environment}-autoscaling-group"
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
  name                   = "${var.project}-${var.environment}-scale-up-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = 1
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project}-${var.environment}-scale-down-policy"
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = -1
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "${var.project}-${var.environment}-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  insufficient_data_actions = []
  ok_actions          = []
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "${var.project}-${var.environment}-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  insufficient_data_actions = []
  ok_actions          = []
}