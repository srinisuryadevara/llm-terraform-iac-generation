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

variable "url_map_default_service" {
  type = string
}

variable "url_map_host_rule_hosts" {
  type = list(string)
}

variable "url_map_path_matcher_path_rule_paths" {
  type = list(string)
}

resource "google_compute_health_check" "default" {
  name                = "default-health-check"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  tcp_health_check {
    port = var.health_check_port
  }
}

resource "google_compute_backend_service" "default" {
  name        = "default-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_url_map" "default" {
  name            = "default-url-map"
  default_service = var.url_map_default_service

  host_rule {
    hosts        = var.url_map_host_rule_hosts
    service      = var.url_map_default_service
  }

  path_matcher {
    name            = "default-path-matcher"
    default_service = var.url_map_default_service

    path_rule {
      paths   = var.url_map_path_matcher_path_rule_paths
      service = var.url_map_default_service
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "default-target-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "default-global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}