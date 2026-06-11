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

variable "subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR"
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

variable "desired_size" {
  type        = number
  description = "Desired Size"
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
  count = length(var.subnet_cidrs)

  vpc_id     = aws_vpc.this.id
  cidr_block = var.subnet_cidrs[count.index]
  availability_zone = "${var.region}${count.index % 3 + 1}"
  tags = {
    Name        = "${var.project}-${var.environment}-subnet-${count.index}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-sg"
  description = "Security Group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
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
  name        = "${var.project}-${var.environment}-role"
  description = "IAM Role"

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
    Name        = "${var.project}-${var.environment}-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.project}-${var.environment}-policy"
  description = "IAM Policy"

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
  name          = "${var.project}-${var.environment}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  tags = {
    Name        = "${var.project}-${var.environment}-lt"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.project}-${var.environment}-asg"
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_size
  vpc_zone_identifier = aws_subnet.this.*.id

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

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "${var.project}-${var.environment}-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Scale up when CPU utilization is above 50%"
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "${var.project}-${var.environment}-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale down when CPU utilization is below 20%"
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
}