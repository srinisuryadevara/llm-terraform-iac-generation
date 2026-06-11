provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "key_alias" {
  type        = string
  description = "KMS key alias"
}

variable "key_description" {
  type        = string
  description = "KMS key description"
}

resource "aws_kms_key" "this" {
  description             = var.key_description
  deletion_window_in_days = 30
  tags = {
    Name        = var.key_alias
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "this" {
  name          = var.key_alias
  target_key_id = aws_kms_key.this.key_id
}

data "aws_iam_policy_document" "key_policy" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [var.project_iam_role_arn]
    }
  }
  statement {
    sid       = "Enable KMS Key Administration"
    effect    = "Allow"
    actions   = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [var.project_iam_role_arn]
    }
  }
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.key_id
  policy = data.aws_iam_policy_document.key_policy.json
}

variable "project_iam_role_arn" {
  type        = string
  description = "Project IAM role ARN"
}