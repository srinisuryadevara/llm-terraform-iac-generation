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
  name        = "backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.default.self_link
  }
}

resource "google_compute_instance_group" "default" {
  name        = "instance-group"
  zone        = var.zone
  instances = [
    google_compute_instance.default.self_link,
  ]
}

resource "google_compute_instance" "default" {
  name         = "instance"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.default.self_link
  }
}

resource "google_compute_network" "default" {
  name                    = "network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.default.self_link
  region        = var.region
}

resource "google_compute_firewall" "default" {
  name    = "firewall"
  network = google_compute_network.default.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["web"]
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.default.self_link
  }

  path_matcher {
    name            = "path-matcher"
    default_service = google_compute_backend_service.default.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.self_link
    }
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}

resource "google_compute_security_policy" "default" {
  name = "security-policy"
}

resource "google_compute_security_policy_rule" "default" {
  policy_id = google_compute_security_policy.default.id
  priority  = 1000

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }

  action = "allow"
}

resource "google_compute_security_policy_association" "default" {
  security_policy_id = google_compute_security_policy.default.id
  backend_service_id = google_compute_backend_service.default.id
}