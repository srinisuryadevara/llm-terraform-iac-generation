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

variable "url_map_default_service" {
  type        = string
  description = "The default service to use for the URL map"
}

variable "health_check_interval_sec" {
  type        = number
  description = "The interval between health checks in seconds"
}

variable "health_check_timeout_sec" {
  type        = number
  description = "The timeout for health checks in seconds"
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "The number of consecutive health check failures before considering a host unhealthy"
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "The number of consecutive health check successes before considering a host healthy"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = var.name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_url_map" "default" {
  name            = var.name
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
  name    = var.name
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = var.name
  target     = google_compute_target_http_proxy.default.id
  port_range = var.port
}

resource "google_compute_health_check" "default" {
  name                = var.name
  check_interval_sec  = var.health_check_interval_sec
  timeout_sec         = var.health_check_timeout_sec
  unhealthy_threshold = var.health_check_unhealthy_threshold
  healthy_threshold   = var.health_check_healthy_threshold

  http_health_check {
    port = var.health_check_port
  }
}