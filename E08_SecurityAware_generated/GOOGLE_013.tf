provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
}

variable "cloud_armor_policy_name" {
  type        = string
  description = "The name of the Cloud Armor policy"
}

variable "backend_service_name" {
  type        = string
  description = "The name of the backend service"
}

resource "google_compute_backend_service" "example" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.example.id]
}

resource "google_compute_health_check" "example" {
  name               = "example-health-check"
  check_interval_sec = 1
  timeout_sec        = 1
  http_health_check {
    port = 80
  }
}

resource "google_compute_security_policy" "example" {
  name        = var.cloud_armor_policy_name
  description = "Example security policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      }
    }
  }

  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

resource "google_compute_security_policy" "example-advanced" {
  name        = "${var.cloud_armor_policy_name}-advanced"
  description = "Example advanced security policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      }
    }
    rate_limit_options {
      exceed {
        action   = "deny(429)"
        threshold = 100
      }
    }
  }

  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

resource "google_compute_backend_service" "example-attached" {
  name        = "${var.backend_service_name}-attached"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  security_policy {
    security_policy = google_compute_security_policy.example.self_link
  }

  health_checks = [google_compute_health_check.example.id]
}

resource "google_compute_firewall" "example" {
  name    = "example-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["example-target-tag"]
}

resource "google_compute_instance" "example" {
  name         = "example-instance"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["example-target-tag"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
  }
}