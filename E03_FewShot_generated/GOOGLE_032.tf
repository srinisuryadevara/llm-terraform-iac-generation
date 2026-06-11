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

resource "google_compute_backend_service" "instance_group" {
  name          = "${var.backend_service_name}-instance-group"
  health_checks = [google_compute_health_check.default.id]
  port_name     = "http"

  backend {
    group = google_compute_instance_group.default.id
  }
}

resource "google_compute_url_map" "instance_group" {
  name            = "${var.url_map_name}-instance-group"
  default_service = google_compute_backend_service.instance_group.id

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.instance_group.id
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.instance_group.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.instance_group.id
    }
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "load-balancer-forwarding-rule"
  target     = google_compute_url_map.default.id
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "instance_group" {
  name       = "load-balancer-forwarding-rule-instance-group"
  target     = google_compute_url_map.instance_group.id
  port_range = "80"
}