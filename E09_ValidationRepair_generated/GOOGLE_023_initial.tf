provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_health_check" "default" {
  name                = var.health_check_name
  check_interval_sec  = var.check_interval_sec
  timeout_sec         = var.timeout_sec
  healthy_threshold   = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold

  http_health_check {
    port         = var.port
    request_path = var.request_path
  }
}

resource "google_compute_security_policy" "default" {
  name        = var.security_policy_name
  description = var.security_policy_description
}

resource "google_compute_security_policy_rule" "default" {
  security_policy = google_compute_security_policy.default.id
  priority        = var.priority
  action          = var.action
  preview         = var.preview

  match {
    versioned_expr = var.versioned_expr
    config {
      src_ip_ranges = var.src_ip_ranges
    }
  }
}

resource "google_compute_backend_service" "with_security_policy" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec

  security_policy {
    security_policy = google_compute_security_policy.default.id
  }

  health_checks = [google_compute_health_check.default.self_link]
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "backend_service_name" {
  type = string
}

variable "port_name" {
  type = string
}

variable "protocol" {
  type = string
}

variable "timeout_sec" {
  type = number
}

variable "health_check_name" {
  type = string
}

variable "check_interval_sec" {
  type = number
}

variable "healthy_threshold" {
  type = number
}

variable "unhealthy_threshold" {
  type = number
}

variable "port" {
  type = number
}

variable "request_path" {
  type = string
}

variable "security_policy_name" {
  type = string
}

variable "security_policy_description" {
  type = string
}

variable "priority" {
  type = number
}

variable "action" {
  type = string
}

variable "preview" {
  type = bool
}

variable "versioned_expr" {
  type = string
}

variable "src_ip_ranges" {
  type = list(string)
}