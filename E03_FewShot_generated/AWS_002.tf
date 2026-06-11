variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "kms_key_alias" {
  type        = string
  description = "KMS Key Alias"
}

variable "kms_key_description" {
  type        = string
  description = "KMS Key Description"
}

variable "kms_key_policy" {
  type        = string
  description = "KMS Key Policy"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "this" {
  description             = var.kms_key_description
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "this" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.key_id
  policy = var.kms_key_policy
}