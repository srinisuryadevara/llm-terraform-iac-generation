locals {
  project           = var.project
  region            = var.region
  security_policy_name = var.security_policy_name
  backend_service_name = var.backend_service_name
}

variable "project" {
  type        = string
  description = "The ID of the project to apply the security policy to"
}

variable "region" {
  type        = string
  description = "The region to apply the security policy to"
}

variable "security_policy_name" {
  type        = string
  description = "The name of the security policy"
}

variable "backend_service_name" {
  type        = string
  description = "The name of the backend service to attach the security policy to"
}

provider "google" {
  project = local.project
  region  = local.region
}

resource "google_compute_backend_service" "example" {
  name        = local.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.example.id]
}

resource "google_compute_health_check" "example" {
  name                = "example-health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port = 80
  }
}

resource "google_compute_security_policy" "example" {
  name        = local.security_policy_name
  description = "Example security policy"
}

resource "google_compute_security_policy_rule" "example" {
  security_policy = google_compute_security_policy.example.id
  priority        = 1000
  rule {
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    action = "allow"
  }
}

resource "google_compute_backend_service_security_policy_association" "example" {
  security_policy = google_compute_security_policy.example.id
  service         = google_compute_backend_service.example.id
}