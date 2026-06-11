provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "example" {
  name        = "example-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.example.self_link
  }

  tags = ["example-backend-service"]
}

resource "google_compute_instance_group" "example" {
  name        = "example-instance-group"
  zone        = var.zone
  instances   = []
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_security_policy" "example" {
  name        = "example-security-policy"
  description = "Example security policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_source_cidrs
      }
    }
  }

  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
        src_ip_ranges_negated = true
      }
    }
  }
}

resource "google_compute_backend_service" "example_with_armor" {
  name        = "example-backend-service-with-armor"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.example.self_link
  }

  security_policy {
    security_policy = google_compute_security_policy.example.self_link
  }

  tags = ["example-backend-service-with-armor"]
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "zone" {
  type        = string
  description = "The zone to deploy to"
}

variable "allowed_source_cidrs" {
  type        = list(string)
  description = "The allowed source CIDRs"
}