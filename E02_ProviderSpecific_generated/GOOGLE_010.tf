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

variable "security_policy_name" {
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
}

resource "google_compute_security_policy" "default" {
  name        = var.security_policy_name
  description = "GCP Cloud Armor security policy"
}

resource "google_compute_security_policy_rule" "default" {
  security_policy = google_compute_security_policy.default.name
  priority        = 1000
  action          = "allow"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["0.0.0.0/0"]
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  security_policy = google_compute_security_policy.default.id
  backend_service  = google_compute_backend_service.default.id
}