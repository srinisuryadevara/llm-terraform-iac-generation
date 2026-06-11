provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = var.tags
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = var.tags
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-firewall"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_cidr]
  target_tags   = ["ssh-server"]
  tags          = var.tags
}

resource "google_compute_instance" "backend" {
  name         = "backend-instance"
  machine_type = var.instance_type
  zone         = var.zone
  tags         = ["ssh-server", "backend-server"]

  boot_disk {
    initialize_params {
      image = var.instance_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "user:${var.ssh_public_key}"
  }
}

resource "google_compute_health_check" "http" {
  name                = "http-health-check"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 1
  unhealthy_threshold = 5

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "backend" {
  name                  = "backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  enable_cdn            = false
  health_checks         = [google_compute_health_check.http.id]
  load_balancing_scheme = "EXTERNAL"

  backend {
    group                 = google_compute_instance_group_manager.instance_group.instance_group
    balancing_mode        = "UTILIZATION"
    capacity_scaler       = 1.0
    max_utilization       = 0.8
  }
}

resource "google_compute_instance_group_manager" "instance_group" {
  name               = "instance-group"
  zone               = var.zone
  instance_template  = google_compute_instance_template.instance_template.id
  target_size        = 1
  base_instance_name = "instance"
}

resource "google_compute_instance_template" "instance_template" {
  name           = "instance-template"
  machine_type   = var.instance_type
  region         = var.region
  tags           = ["ssh-server", "backend-server"]

  disk {
    source_image = var.instance_image
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "user:${var.ssh_public_key}"
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "url-map"
  default_service = google_compute_backend_service.backend.id

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.backend.id
  }

  path_matcher {
    name            = "path-matcher"
    default_service = google_compute_backend_service.backend.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.backend.id
    }
  }

  ssl_policy {
    min_tls_version = "TLS_1_2"
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "http-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "ssh_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "zone" {
  type = string
}

variable "instance_image" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "tags" {
  type = list(string)
}