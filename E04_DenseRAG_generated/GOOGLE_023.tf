terraform {
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
  port_name        = "http"
  protocol         = "HTTP"
  timeout_sec      = 10
  enable_cdn       = false
  security_policy  = google_compute_security_policy.default.id
}

resource "google_compute_security_policy" "default" {
  project = var.project
  name    = "cloud-armor-policy"
}

resource "google_compute_security_policy_rule" "default" {
  project     = var.project
  security_policy = google_compute_security_policy.default.name
  priority    = 1000
  action      = "allow"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }
  rate_limit_options {
    exceed {
      action = "allow"
    }
  }
}