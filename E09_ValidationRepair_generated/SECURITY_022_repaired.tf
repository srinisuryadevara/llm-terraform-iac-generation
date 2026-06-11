provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "alb_arn" {
  type        = string
  description = "ALB ARN"
}

variable "waf_rule_group_arns" {
  type        = list(string)
  description = "List of WAF Rule Group ARNs"
}

resource "aws_wafv2_web_acl" "example" {
  name        = "example-web-acl"
  description = "Example WAF Web ACL"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.waf_rule_group_arns
    content {
      name     = "rule-${rule.value}"
      priority = length(var.waf_rule_group_arns) - index(var.waf_rule_group_arns, rule.value)

      override_action {
        count {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"

          dynamic "excluded_rule" {
            for_each = ["GenericRFI"]
            content {
              name = excluded_rule.value
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "example-web-acl-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "example-web-acl-metric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "example-web-acl"
    Environment = "example"
  }
}

resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.example.arn

  tags = {
    Name        = "example-web-acl-association"
    Environment = "example"
  }
}

output "web_acl_id" {
  value       = aws_wafv2_web_acl.example.id
  description = "The ID of the WAF Web ACL"
}

output "web_acl_arn" {
  value       = aws_wafv2_web_acl.example.arn
  description = "The ARN of the WAF Web ACL"
}

output "web_acl_association_id" {
  value       = aws_wafv2_web_acl_association.example.id
  description = "The ID of the WAF Web ACL Association"
}