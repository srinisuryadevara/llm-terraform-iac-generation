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

variable "alb_arn" {
  type        = string
  description = "ALB ARN"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR Blocks for SSH"
}

resource "aws_wafv2_web_acl" "example" {
  name        = "example-web-acl"
  description = "Example Web ACL"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    managed_rule_group_statement {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"

      excluded_rule {
        name = "SizeRestrictions_BODY"
      }

      excluded_rule {
        name = "CrossSiteScripting_BODY"
      }
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      count {}
    }

    managed_rule_group_statement {
      name        = "AWSManagedRulesSQLiRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "example-web-acl-metric"
    sampled_requests_enabled   = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.example.arn
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Example Security Group"

  ingress {
    description = "Allow HTTP from specific CIDR blocks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "Allow HTTPS from specific CIDR blocks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "example" {
  name        = "example-iam-role"
  description = "Example IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_policy" "example" {
  name        = "example-iam-policy"
  description = "Example IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "wafv2:GetWebACL",
          "wafv2:UpdateWebACL",
        ]
        Effect = "Allow"
        Resource = aws_wafv2_web_acl.example.arn
      },
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}