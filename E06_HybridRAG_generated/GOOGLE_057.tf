terraform {
  required_version = ">= 0.12.8"
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
  }
}

provider "google" {
  credentials = "${file(var.credentials_file)}"
  version     = "~> 3.45.0"
  project     = var.project
  region      = var.region
}

variable "project" {
  type        = string
  description = "The ID of the project to apply the security policy to"
}

variable "region" {
  type        = string
  description = "The region to apply the security policy to"
}

variable "credentials_file" {
  type        = string
  description = "The path to the credentials file"
}

variable "security_policy_name" {
  type        = string
  description = "The name of the security policy"
}

variable "backend_service_name" {
  type        = string
  description = "The name of the backend service"
}

resource "google_compute_backend_service" "default" {
  project          = var.project
  name             = var.backend_service_name
  protocol         = "HTTP"
  timeout_sec      = 10
  port_name        = "http"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_security_policy" "default" {
  project     = var.project
  name        = var.security_policy_name
  description = "Example security policy"
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
}

resource "google_compute_security_policy" "attached" {
  project     = var.project
  name        = "${var.security_policy_name}-attached"
  description = "Attached security policy"
  rule {
    priority    = 1000
    action      = "allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

resource "google_compute_backend_service" "attached" {
  project          = var.project
  name             = "${var.backend_service_name}-attached"
  protocol         = "HTTP"
  timeout_sec      = 10
  port_name        = "http"
  load_balancing_scheme = "EXTERNAL"
  security_policy {
    security_policy = google_compute_security_policy.attached.id
  }
}