variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "port" {
  type = number
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

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_backend_service" "this" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.this.self_link]
}

resource "google_compute_health_check" "this" {
  name               = "${var.name}-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
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
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.this.self_link
}

resource "google_compute_global_forwarding_rule" "this" {
  name       = "${var.name}-global-forwarding-rule"
  target     = google_compute_target_http_proxy.this.self_link
  port_range = var.port
}