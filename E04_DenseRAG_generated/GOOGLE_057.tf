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
  project      = var.project
  name         = "backend-service"
  port_name    = "http"
  protocol     = "HTTP"
  timeout_sec  = 10
  enable_cdn   = false

  backend {
    group = google_compute_instance_group.default.self_link
  }
}

resource "google_compute_instance_group" "default" {
  project      = var.project
  name         = "instance-group"
  zone         = var.zone
  instances    = [google_compute_instance.default.self_link]
}

resource "google_compute_instance" "default" {
  project      = var.project
  zone         = var.zone
  name         = "instance"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    subnetwork = var.subnet
  }
}

resource "google_compute_security_policy" "default" {
  project = var.project
  name    = "security-policy"
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

resource "google_compute_backend_service_security_policy_association" "default" {
  project               = var.project
  security_policy       = google_compute_security_policy.default.id
  backend_service       = google_compute_backend_service.default.id
}