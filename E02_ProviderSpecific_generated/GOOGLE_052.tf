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

variable "backend_service_port" {
  type = number
}

variable "instance_group_url" {
  type = string
}

resource "google_compute_health_check" "default" {
  name               = "load-balancer-health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = var.health_check_port
  }
}

resource "google_compute_backend_service" "default" {
  name        = "load-balancer-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [
    google_compute_health_check.default.id
  ]
}

resource "google_compute_url_map" "default" {
  name            = "load-balancer-url-map"
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
  name    = "load-balancer-target-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "load-balancer-global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}