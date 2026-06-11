terraform {
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
    google-beta = {
      version = ">= 3.45.0"
    }
  }
}

provider "google" {
  credentials = "${file("account.json")}"
  version     = "~> 3.45.0"
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  credentials = "${file("account.json")}"
  version     = "~> 3.45.0"
  project     = var.project
  region      = var.region
}

resource "google_compute_backend_service" "default" {
  provider              = google
  name                  = "backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  port_name             = "http"
  port                  = 80
  timeout_sec           = 10
}

resource "google_compute_url_map" "default" {
  provider        = google
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  provider = google
  name     = "http-proxy"
  url_map  = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "global-forwarding-rule"
  target                = google_compute_target_http_proxy.default.self_link
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_security_policy" "default" {
  provider = google-beta
  name     = "security-policy"
}

resource "google_compute_security_policy_rule" "default" {
  provider = google-beta
  security_policy = google_compute_security_policy.default.name
  priority        = 1000
  action          = "allow"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }
}

resource "google_compute_security_policy_rule" "deny" {
  provider = google-beta
  security_policy = google_compute_security_policy.default.name
  priority        = 2000
  action          = "deny(403)"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["192.168.1.1/32"]
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  provider                  = google-beta
  backend_service           = google_compute_backend_service.default.id
  security_policy           = google_compute_security_policy.default.id
}