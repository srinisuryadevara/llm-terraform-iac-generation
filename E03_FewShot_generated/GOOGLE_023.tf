variable "project_id" {
  type        = string
  sensitive   = true
}

variable "security_policy_name" {
  type        = string
}

variable "backend_service_name" {
  type        = string
}

variable "security_policy_rule_action" {
  type        = string
}

variable "security_policy_rule_priority" {
  type        = number
}

variable "security_policy_rule_description" {
  type        = string
}

variable "security_policy_rule_match_config" {
  type = object({
    versioned_expr = string
    config = object({
      src_ip_ranges = list(string)
    })
  })
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [
    google_compute_health_check.default.id,
  ]
}

resource "google_compute_health_check" "default" {
  name                = "health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_security_policy" "default" {
  name        = var.security_policy_name
  project     = var.project_id
}

resource "google_compute_security_policy_rule" "default" {
  policy_id = google_compute_security_policy.default.id
  priority  = var.security_policy_rule_priority

  action   = var.security_policy_rule_action
  preview  = false
  description = var.security_policy_rule_description

  match {
    versioned_expr = var.security_policy_rule_match_config.versioned_expr
    config {
      src_ip_ranges = var.security_policy_rule_match_config.config.src_ip_ranges
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  service    = google_compute_backend_service.default.id
  policy     = google_compute_security_policy.default.id
}