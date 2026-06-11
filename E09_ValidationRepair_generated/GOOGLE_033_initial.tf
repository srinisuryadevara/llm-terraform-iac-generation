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

variable "instance_group_name" {
  type = string
}

variable "instance_group_zone" {
  type = string
}

resource "google_compute_health_check" "default" {
  name                = "load-balancer-health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  tcp_health_check {
    port = var.health_check_port
  }
}

resource "google_compute_backend_service" "default" {
  name        = "load-balancer-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.default.self_link
  }

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_instance_group" "default" {
  name        = var.instance_group_name
  zone        = var.instance_group_zone
  instances   = []
  description = "Instance group for load balancer"
}

resource "google_compute_url_map" "default" {
  name            = "load-balancer-url-map"
  default_service = google_compute_backend_service.default.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.default.self_link
  }

  path_matcher {
    name            = "path-matcher"
    default_service = google_compute_backend_service.default.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "load-balancer-target-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "load-balancer-global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}