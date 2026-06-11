terraform {
  required_version = ">= 0.12.8"
  required_providers {
    google = {
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

variable "project" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "backend_service_name" {
  type        = string
  description = "The name of the backend service"
}

variable "security_policy_name" {
  type        = string
  description = "The name of the Cloud Armor security policy"
}

resource "google_compute_backend_service" "default" {
  provider      = google
  name          = var.backend_service_name
  project       = var.project
  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_health_check" "default" {
  provider = google
  name     = "health-check"
  project  = var.project

  tcp_health_check {
    port = 80
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  provider      = google
  name          = "global-forwarding-rule"
  project       = var.project
  target        = google_compute_target_http_proxy.default.self_link
  port_range    = "80"
}

resource "google_compute_target_http_proxy" "default" {
  provider = google
  name     = "target-http-proxy"
  project  = var.project
  url_map  = google_compute_url_map.default.self_link
}

resource "google_compute_url_map" "default" {
  provider        = google
  name            = "url-map"
  project         = var.project
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_security_policy" "default" {
  provider = google-beta
  name     = var.security_policy_name
  project  = var.project
}

resource "google_compute_security_policy_rule" "default" {
  provider        = google-beta
  security_policy = google_compute_security_policy.default.self_link
  project         = var.project
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
  provider                  = google-beta
  security_policy           = google_compute_security_policy.default.self_link
  backend_service           = google_compute_backend_service.default.self_link
  project                   = var.project
}