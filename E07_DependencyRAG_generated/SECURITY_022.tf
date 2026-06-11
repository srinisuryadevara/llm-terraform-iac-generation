terraform {
  required_version = ">= 1.4, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
    }
  }
}

variable "alb_name" {
  type        = string
  description = "The name of the ALB"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets"
}

variable "security_group_ids" {
  type        = list(string)
  description = "The IDs of the security groups"
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resources"
}

variable "waf_enable" {
  type        = bool
  description = "Whether to enable WAF"
}

variable "managed_rule_group_names" {
  type        = list(string)
  description = "The names of the managed rule groups to attach"
}

resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    enabled = true
  }

  tags = merge({ Name = var.alb_name }, var.tags)
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.alb_name}-access-logs"
  acl    = "private"

  tags = merge({ Name = "${var.alb_name}-access-logs" }, var.tags)
}

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.alb_name}-web-acl"
  description = "Web ACL for ${var.alb_name}"
  scope       = "REGIONAL"

  dynamic "rule" {
    for_each = var.managed_rule_group_names

    content {
      name     = rule.value
      priority = rule.key + 1

      override_action {
        count {}
      }

      managed_rule_group_statement {
        name        = rule.value
        vendor_name = "AWS"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.alb_name}-web-acl-metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "main" {
  count        = var.waf_enable ? 1 : 0
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

resource "aws_lb_target_group" "main" {
  name        = "${var.alb_name}-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 3
    path                = "/"
    unhealthy_threshold = 2
  }

  tags = merge({ Name = "${var.alb_name}-target-group" }, var.tags)
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}