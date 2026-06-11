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

variable "health_check_unhealthy_threshold" {
  type        = number
  default     = 2
}

variable "health_check_healthy_threshold" {
  type        = number
  default     = 2
}

resource "google_compute_health_check" "default" {
  name                = "load-balancer-health-check"
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  unhealthy_threshold = var.health_check_unhealthy_threshold
  healthy_threshold   = var.health_check_healthy_threshold
  labels = {
    environment = "dev"
  }

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "default" {
  name                  = "load-balancer-backend-service"
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  enable_cdn            = false
  health_checks         = [google_compute_health_check.default.id]
  labels = {
    environment = "dev"
  }

  backend {
    group = google_compute_instance_group.default.id
  }
}

resource "google_compute_instance_group" "default" {
  name        = "load-balancer-instance-group"
  zone        = "${var.region}-a"
  instances  = []
  named_port {
    name = "http"
    port = 80
  }
  labels = {
    environment = "dev"
  }
}

resource "google_compute_url_map" "default" {
  name            = "load-balancer-url-map"
  default_service = google_compute_backend_service.default.id
  labels = {
    environment = "dev"
  }

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
  labels = {
    environment = "dev"
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "load-balancer-global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  labels = {
    environment = "dev"
  }
}

output "health_check_id" {
  value = google_compute_health_check.default.id
}

output "backend_service_id" {
  value = google_compute_backend_service.default.id
}

output "instance_group_id" {
  value = google_compute_instance_group.default.id
}

output "url_map_id" {
  value = google_compute_url_map.default.id
}

output "target_http_proxy_id" {
  value = google_compute_target_http_proxy.default.id
}

output "global_forwarding_rule_id" {
  value = google_compute_global_forwarding_rule.default.id
}

output "global_forwarding_rule_ip" {
  value = google_compute_global_forwarding_rule.default.ip_address
}