terraform {
  required_version = ">= 0.12.8"
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
}

variable "credentials_file" {
  type        = string
  sensitive   = true
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "backend_service_name" {
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
  name                = "health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port = 80
  }
}

resource "google_compute_security_policy" "default" {
  name        = var.policy_name
  description = "Example security policy"
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
  security_policy = google_compute_security_policy.default.id
  service         = google_compute_backend_service.default.id
}