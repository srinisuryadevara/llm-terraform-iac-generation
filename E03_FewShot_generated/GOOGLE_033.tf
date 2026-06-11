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

variable "health_check_timeout" {
  type        = number
  default     = 5
}

variable "health_check_interval" {
  type        = number
  default     = 30
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
  name                = "health-check"
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "default" {
  name                  = var.backend_service_name
  health_checks         = [google_compute_health_check.default.id]
  load_balancing_scheme = "EXTERNAL"
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
  zone        = "${var.region}-a"
  instances   = []
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_forwarding_rule" "default" {
  name       = "forwarding-rule"
  region     = var.region
  ports      = ["80"]
  target     = google_compute_target_pool.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-forwarding-rule"
  target     = google_compute_url_map.default.id
  port_range = "80"
}