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
  labels = {
    environment = "production"
    application = "cloud-armor"
  }

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  name                = "health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10
  labels = {
    environment = "production"
    application = "cloud-armor"
  }

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_security_policy" "default" {
  name        = var.security_policy_name
  description = "Cloud Armor security policy"
  labels = {
    environment = "production"
    application = "cloud-armor"
  }
}

resource "google_compute_security_policy_rule" "default" {
  security_policy = google_compute_security_policy.default.id
  priority        = 1000
  action          = "allow"
  labels = {
    environment = "production"
    application = "cloud-armor"
  }
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

output "backend_service_id" {
  value = google_compute_backend_service.default.id
}

output "security_policy_id" {
  value = google_compute_security_policy.default.id
}

output "health_check_id" {
  value = google_compute_health_check.default.id
}