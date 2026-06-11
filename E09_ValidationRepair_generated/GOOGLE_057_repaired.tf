provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec
  labels      = {
    environment = "production"
    service     = "backend"
  }

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
  labels      = {
    environment = "production"
    service     = "security-policy"
  }
}

resource "google_compute_security_policy_rule" "default" {
  policy_id = google_compute_security_policy.default.id
  priority  = var.priority
  labels    = {
    environment = "production"
    service     = "security-policy-rule"
  }

  match {
    versioned_expr = var.versioned_expr
    config {
      src_ip_ranges = var.src_ip_ranges
    }
  }

  action = var.action
}

output "backend_service_id" {
  value = google_compute_backend_service.default.id
}

output "security_policy_id" {
  value = google_compute_security_policy.default.id
}

output "security_policy_rule_id" {
  value = google_compute_security_policy_rule.default.id
}