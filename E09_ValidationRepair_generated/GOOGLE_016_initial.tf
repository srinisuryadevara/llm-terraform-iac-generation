provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "health_check_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "backend_service_name" {
  type = string
}

variable "url_map_name" {
  type = string
}

variable "target_pool_name" {
  type = string
}

variable "instance_group_name" {
  type = string
}

resource "google_compute_instance_group" "instance_group" {
  name        = var.instance_group_name
  description = "Instance group for load balancer"
  zone        = "${var.region}-a"
  instances = [
    google_compute_instance.instance.self_link
  ]
}

resource "google_compute_instance" "instance" {
  name         = "instance"
  machine_type = "f1-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.network.self_link
    access_config {
    }
  }
}

resource "google_compute_network" "network" {
  name                    = "network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.network.self_link
  region        = var.region
}

resource "google_compute_health_check" "health_check" {
  name                = "health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = var.backend_service_name
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  enable_cdn            = false
  health_checks         = [google_compute_health_check.health_check.self_link]
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_instance_group.instance_group.self_link
  }
}

resource "google_compute_url_map" "url_map" {
  name            = var.url_map_name
  default_service = google_compute_backend_service.backend_service.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.backend_service.self_link
  }

  path_matcher {
    name            = "path-matcher"
    default_service = google_compute_backend_service.backend_service.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.backend_service.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "target-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "global-forwarding-rule"
  target     = google_compute_target_http_proxy.target_http_proxy.self_link
  port_range = "80"
}