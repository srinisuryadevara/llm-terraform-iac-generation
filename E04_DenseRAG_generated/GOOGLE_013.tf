terraform {
  required_version = ">= 0.12.8"
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
    null = {
      version = ">= 2.1.0"
    }
  }
}

provider "google" {
  credentials = "${file("account.json")}"
  version     = "~> 3.45.0"
  project     = var.project
  region      = var.region

  scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  credentials = "${file("account.json")}"
  version     = "~> 3.45.0"
  project     = var.project
  region      = var.region

  scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

resource "google_compute_backend_service" "default" {
  project          = var.project
  name             = "backend-service"
  protocol         = "HTTP"
  timeout_sec      = 10
  port_name        = "http"
  load_balancing_scheme = "EXTERNAL"
  health_checks    = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  project            = var.project
  name               = "health-check"
  check_interval_sec = 1
  timeout_sec        = 1
  http_health_check {
    port = 80
  }
}

resource "google_compute_security_policy" "default" {
  project     = var.project
  name        = "security-policy"
  description = "Security policy for backend service"
}

resource "google_compute_security_policy_rule" "default" {
  project     = var.project
  security_policy = google_compute_security_policy.default.id
  priority    = 1000
  action      = "allow"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["0.0.0.0/0"]
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  project                  = var.project
  backend_service          = google_compute_backend_service.default.id
  security_policy          = google_compute_security_policy.default.id
}