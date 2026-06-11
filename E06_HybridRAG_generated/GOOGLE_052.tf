variable "project" {
  type        = string
  description = "The ID of the project to create"
}

variable "region" {
  type        = string
  description = "The region to create the load balancer in"
}

variable "name" {
  type        = string
  description = "The name of the load balancer"
}

variable "port" {
  type        = number
  description = "The port to use for the load balancer"
}

variable "health_check_port" {
  type        = number
  description = "The port to use for the health check"
}

variable "backend_service_name" {
  type        = string
  description = "The name of the backend service"
}

variable "url_map_name" {
  type        = string
  description = "The name of the URL map"
}

variable "health_check_name" {
  type        = string
  description = "The name of the health check"
}

variable "instance_group_name" {
  type        = string
  description = "The name of the instance group"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_backend_service" "this" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.this.self_link
  }

  health_checks = [google_compute_health_check.this.self_link]
}

resource "google_compute_url_map" "this" {
  name            = var.url_map_name
  default_service = google_compute_backend_service.this.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.this.self_link
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.this.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.this.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "this" {
  name    = "http-proxy"
  url_map = google_compute_url_map.this.self_link
}

resource "google_compute_global_forwarding_rule" "this" {
  name       = "global-forwarding-rule"
  target     = google_compute_target_http_proxy.this.self_link
  port_range = "80"
}

resource "google_compute_instance_group" "this" {
  name        = var.instance_group_name
  zone        = "${var.region}-a"
  instances = [
    google_compute_instance.this.self_link,
  ]
}

resource "google_compute_instance" "this" {
  name         = "instance"
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
}

resource "google_compute_health_check" "this" {
  name               = var.health_check_name
  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = var.health_check_port
  }
}