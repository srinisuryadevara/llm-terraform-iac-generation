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

variable "web_acl_name" {
  type        = string
  description = "Web ACL Name"
}

variable "managed_rule_group_names" {
  type        = list(string)
  description = "Managed Rule Group Names"
}

resource "aws_waf_web_acl" "this" {
  name        = var.web_acl_name
  metric_name = var.web_acl_name

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.managed_rule_group_names
    content {
      priority = rule.key + 1
      rule_id  = aws_waf_rule.this[rule.value].id
      action {
        allow {}
      }
    }
  }

  tags = {
    Name = var.web_acl_name
  }
}

resource "aws_waf_rule" "this" {
  for_each = toset(var.managed_rule_group_names)

  name        = each.value
  metric_name = each.value

  dynamic "predicate" {
    for_each = [each.value]
    content {
      data_id = aws_waf_managed_rule_group.this[each.value].id
      negated = false
      type    = "ManagedRuleGroup"
    }
  }
}

resource "aws_waf_managed_rule_group" "this" {
  for_each = toset(var.managed_rule_group_names)

  name        = each.value
  metric_name = each.value

  vendor_name = "AWS"
}

resource "aws_waf_web_acl_association" "this" {
  resource_arn = var.alb_arn
  web_acl_id   = aws_waf_web_acl.this.id
}