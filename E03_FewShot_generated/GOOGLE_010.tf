provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "example" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec

  backend {
    group = var.instance_group
  }

  security_policy {
    security_policy = google_compute_security_policy.example.id
  }
}

resource "google_compute_security_policy" "example" {
  name        = var.security_policy_name
  description = var.security_policy_description
}

resource "google_compute_security_policy_rule" "example" {
  security_policy = google_compute_security_policy.example.id
  priority        = var.rule_priority
  action          = var.rule_action
  match {
    versioned_expr = var.match_versioned_expr
    config {
      src_ip_ranges = var.src_ip_ranges
    }
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "backend_service_name" {
  type        = string
}

variable "port_name" {
  type        = string
}

variable "protocol" {
  type        = string
}

variable "timeout_sec" {
  type        = number
}

variable "instance_group" {
  type        = string
}

variable "security_policy_name" {
  type        = string
}

variable "security_policy_description" {
  type        = string
}

variable "rule_priority" {
  type        = number
}

variable "rule_action" {
  type        = string
}

variable "match_versioned_expr" {
  type        = string
}

variable "src_ip_ranges" {
  type        = list(string)
}