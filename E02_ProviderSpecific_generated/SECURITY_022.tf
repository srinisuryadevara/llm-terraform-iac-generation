provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "alb_arn" {
  type        = string
  sensitive   = true
}

resource "aws_wafv2_web_acl" "example" {
  name        = "example-web-acl"
  description = "Example WAF Web ACL"
  scope       = "REGIONAL"

  rule {
    name     = "awsmanagedrulescommonrule"
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
        name = "NoUserAgent_HEADER"
      }
    }
  }

  rule {
    name     = "awsmanagedrulesknownbadinputsrule"
    priority = 2

    override_action {
      count {}
    }

    managed_rule_group_statement {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "example-web-acl-metric"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = var.alb_arn
  web_acl_arn   = aws_wafv2_web_acl.example.arn
}