variable "description" {
  type        = string
  description = "The description of the key"
}

variable "policy" {
  type        = string
  description = "The policy of the key"
}

variable "enable_key_rotation" {
  type        = bool
  description = "Whether key rotation is enabled"
}

variable "deletion_window_in_days" {
  type        = number
  description = "The number of days after which the key is deleted after destruction of the resource"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the key"
}

variable "alias" {
  type        = string
  description = "The alias of the key"
}

resource "aws_kms_key" "this" {
  description             = var.description
  policy                  = var.policy
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = var.alias
  target_key_id = aws_kms_key.this.key_id
}