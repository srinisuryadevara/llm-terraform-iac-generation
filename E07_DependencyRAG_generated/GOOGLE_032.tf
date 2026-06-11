# Configure the Google Cloud Provider
provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project
}

# Variables
variable "region" {
  type        = string
  description = "The region to create the load balancer in"
}

variable "project" {
  type        = string
  description = "The project to create the load balancer in"
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

# Create a backend service
resource "google_compute_backend_service" "default" {
  name        = var.name
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.self_link]
}

# Create a health check
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

# Create a URL map
resource "google_compute_url_map" "default" {
  name            = var.name
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

# Create a target HTTP proxy
resource "google_compute_target_http_proxy" "default" {
  name    = var.name
  url_map = google_compute_url_map.default.self_link
}

# Create a forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name       = var.name
  target     = google_compute_target_http_proxy.default.self_link
  port_range = var.port
}