provider "google" {
  project = var.project_id
  region  = var.region
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

variable "security_policy_name" {
  type = string
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  name               = "health-check"
  timeout_sec       = 1
  check_interval_sec = 1

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_security_policy" "default" {
  name        = var.security_policy_name
  description = "Security policy example"
}

resource "google_compute_security_policy_rule" "default" {
  security_policy = google_compute_security_policy.default.name
  priority        = 1000

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["0.0.0.0/0"]
    }
  }

  action = "allow"
}

resource "google_compute_backend_service_security_policy_association" "default" {
  security_policy = google_compute_security_policy.default.id
  backend_service = google_compute_backend_service.default.id
}