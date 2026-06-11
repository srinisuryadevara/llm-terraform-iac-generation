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

variable "health_check_path" {
  type        = string
  description = "The path to use for the health check"
}

variable "health_check_port" {
  type        = number
  description = "The port to use for the health check"
}

variable "instance_group" {
  type        = string
  description = "The instance group to use for the backend service"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_health_check" "default" {
  name                = "${var.name}-health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "default" {
  name        = "${var.name}-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = var.instance_group
  }

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_url_map" "default" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.default.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.default.self_link
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.name}-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = var.port
}