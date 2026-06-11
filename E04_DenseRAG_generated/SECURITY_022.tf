terraform {
  required_version = ">= 1.4, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
    }
  }
}

variable "waf_name" {
  type        = string
  description = "Name of the WAF WebACL"
}

variable "alb_arn" {
  type        = string
  description = "ARN of the ALB to attach the WAF WebACL to"
}

variable "managed_rule_group_names" {
  type        = list(string)
  description = "List of managed rule group names to attach to the WAF WebACL"
}

resource "aws_wafv2_web_acl" "main" {
  name        = var.waf_name
  description = "Managed rule groups WebACL"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.managed_rule_group_names

    content {
      name     = rule.value
      priority = length(var.managed_rule_group_names) - index(var.managed_rule_group_names, rule.value)

      override_action {
        count {}
      }

      managed_rule_group_statement {
        name        = rule.value
        vendor_name = "AWS"

        excluded_rule {
          rule_label {
            name = "RuleLabelExample"
          }
        }
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.waf_name
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}