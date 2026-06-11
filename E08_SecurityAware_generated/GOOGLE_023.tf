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

variable "tls_min_version" {
  type        = string
  default     = "1.2"
  description = "The minimum TLS version"
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  log_config {
    enable = true
  }

  security_policy {
    security_policy = google_compute_security_policy.default.id
  }
}

resource "google_compute_security_policy" "default" {
  name        = var.cloud_armor_policy_name
  description = "Cloud Armor security policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [var.ssh_source_cidr]
      }
    }
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  tls_min_version = var.tls_min_version

  labels = {
    environment = "prod"
  }
}

resource "google_compute_firewall" "default" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]

  target_tags = ["ssh-access"]

  labels = {
    environment = "prod"
  }
}

resource "google_compute_instance" "default" {
  name         = "test-instance"
  machine_type = "f1-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
  }

  labels = {
    environment = "prod"
  }

  metadata = {
    ssh-keys = "user:${file("~/.ssh/id_rsa.pub")}"
  }
}