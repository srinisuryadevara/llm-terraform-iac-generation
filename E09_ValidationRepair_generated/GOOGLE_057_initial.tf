provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec

  backend {
    group = var.instance_group
  }

  security_policy {
    security_policy = google_compute_security_policy.default.id
  }
}

resource "google_compute_security_policy" "default" {
  name        = var.security_policy_name
  description = var.security_policy_description
}

resource "google_compute_security_policy_rule" "default" {
  policy_id = google_compute_security_policy.default.id
  priority  = var.priority

  match {
    versioned_expr = var.versioned_expr
    config {
      src_ip_ranges = var.src_ip_ranges
    }
  }

  action = var.action
}