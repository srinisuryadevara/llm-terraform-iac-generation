provider "google" {
  project = var.project_id
  region  = var.region
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
  sensitive   = true
}

variable "security_policy_name" {
  type        = string
  sensitive   = true
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.id]
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
  description = "Cloud Armor security policy"
}

resource "google_compute_security_policy_rule" "default" {
  security_policy = google_compute_security_policy.default.id
  priority        = 1000
  action          = "allow"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  service     = google_compute_backend_service.default.id
  policy      = google_compute_security_policy.default.id
}