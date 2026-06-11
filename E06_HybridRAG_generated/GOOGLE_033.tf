variable "project" {
  type        = string
  description = "The ID of the project to create the load balancer in"
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

variable "health_check_path" {
  type        = string
  description = "The path to use for the health check"
}

variable "backend_service_name" {
  type        = string
  description = "The name of the backend service"
}

variable "url_map_name" {
  type        = string
  description = "The name of the URL map"
}

variable "default_service_name" {
  type        = string
  description = "The name of the default service"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
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

resource "google_compute_url_map" "default" {
  name            = var.url_map_name
  default_service = google_compute_backend_service.default.id

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.default.id
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.id
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = var.name
  target     = google_compute_target_http_proxy.default.id
  port_range = var.port
}