locals {
  project           = "my-project"
  region            = "us-central1"
  security_policy_name = "my-security-policy"
  backend_service_name = "my-backend-service"
}

terraform {
  backend "gcs" {
    prefix = "cloud-armor/state"
    bucket = "terraform-my-project"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

resource "google_compute_backend_service" "default" {
  name          = local.backend_service_name
  port_name     = "http"
  protocol      = "HTTP"
  timeout_sec   = 10
  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  name               = "my-health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = 80
  }
}

resource "google_compute_security_policy" "default" {
  name        = local.security_policy_name
  description = "Security policy for Cloud Armor"
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
  backend_service = google_compute_backend_service.default.id
  security_policy = google_compute_security_policy.default.id
}