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
  credentials = "${file(var.credentials_file)}"
  version     = "~> 2.9.0"
  project     = var.project
  region      = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  credentials = "${file(var.credentials_file)}"
  version     = "~> 2.9.0"
  project     = var.project
  region      = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
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

resource "google_compute_security_policy_rule" "deny" {
  project     = var.project
  security_policy = google_compute_security_policy.default.name
  priority    = 2147483647
  action      = "deny(403)"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  project                  = var.project
  security_policy          = google_compute_security_policy.default.id
  backend_service          = google_compute_backend_service.default.id
}