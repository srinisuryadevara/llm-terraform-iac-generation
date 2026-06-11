terraform {
  required_version = ">= 0.12.8"
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
  provider              = google
  name                  = var.backend_service_name
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  port_name             = "http"
  timeout_sec           = 10
}

resource "google_compute_security_policy" "default" {
  provider = google-beta
  name     = var.security_policy_name
}

resource "google_compute_security_policy_rule" "default" {
  provider = google-beta
  policy   = google_compute_security_policy.default.name
  priority = 1000
  action   = "allow"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["0.0.0.0/0"]
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  provider            = google-beta
  security_policy     = google_compute_security_policy.default.id
  backend_service     = google_compute_backend_service.default.id
}