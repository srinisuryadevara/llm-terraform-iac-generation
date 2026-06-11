provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "health_check_port" {
  type        = number
  default     = 80
}

variable "health_check_path" {
  type        = string
  default     = "/"
}

variable "backend_service_name" {
  type        = string
}

variable "url_map_name" {
  type        = string
}

variable "target_pool_name" {
  type        = string
}

variable "instance_group_name" {
  type        = string
}

resource "google_compute_health_check" "default" {
  name                = "load-balancer-health-check"
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
  name          = var.backend_service_name
  health_checks = [google_compute_health_check.default.id]
  port_name     = "http"
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

resource "google_compute_target_pool" "default" {
  name = var.target_pool_name

  instances = [
    google_compute_instance_group.default.id,
  ]

  health_checks = [
    google_compute_health_check.default.id,
  ]
}

resource "google_compute_instance_group" "default" {
  name        = var.instance_group_name
  instances   = []
  zone        = "${var.region}-a"
}

resource "google_compute_forwarding_rule" "default" {
  name       = "load-balancer-forwarding-rule"
  region     = var.region
  ports      = ["80"]
  target     = google_compute_target_pool.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "load-balancer-global-forwarding-rule"
  ip_address = google_compute_global_address.default.address
  port_range = "80"
  target     = google_compute_target_http_proxy.default.id
}

resource "google_compute_global_address" "default" {
  name = "load-balancer-global-address"
}

resource "google_compute_target_http_proxy" "default" {
  name    = "load-balancer-target-http-proxy"
  url_map = google_compute_url_map.default.id
}