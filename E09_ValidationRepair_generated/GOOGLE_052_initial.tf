provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec
  enable_cdn  = var.enable_cdn

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_url_map" "default" {
  name            = var.url_map_name
  default_service = google_compute_backend_service.default.self_link

  host_rule {
    hosts        = [var.host]
    service      = google_compute_backend_service.default.self_link
  }

  path_matcher {
    name            = var.path_matcher_name
    default_service = google_compute_backend_service.default.self_link

    path_rule {
      paths   = [var.path]
      service = google_compute_backend_service.default.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = var.target_http_proxy_name
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = var.global_forwarding_rule_name
  target     = google_compute_target_http_proxy.default.self_link
  port_range = var.port_range
}

resource "google_compute_health_check" "default" {
  name                = var.health_check_name
  check_interval_sec  = var.check_interval_sec
  timeout_sec         = var.timeout_sec
  healthy_threshold   = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold

  http_health_check {
    port = var.port
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "backend_service_name" {
  type        = string
  default     = "default-backend-service"
}

variable "port_name" {
  type        = string
  default     = "http"
}

variable "protocol" {
  type        = string
  default     = "HTTP"
}

variable "timeout_sec" {
  type        = number
  default     = 10
}

variable "enable_cdn" {
  type        = bool
  default     = false
}

variable "url_map_name" {
  type        = string
  default     = "default-url-map"
}

variable "host" {
  type        = string
  default     = "*"
}

variable "path_matcher_name" {
  type        = string
  default     = "default-path-matcher"
}

variable "path" {
  type        = string
  default     = "/*"
}

variable "target_http_proxy_name" {
  type        = string
  default     = "default-target-http-proxy"
}

variable "global_forwarding_rule_name" {
  type        = string
  default     = "default-global-forwarding-rule"
}

variable "port_range" {
  type        = string
  default     = "80"
}

variable "health_check_name" {
  type        = string
  default     = "default-health-check"
}

variable "check_interval_sec" {
  type        = number
  default     = 10
}

variable "healthy_threshold" {
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  type        = number
  default     = 2
}

variable "port" {
  type        = number
  default     = 80
}