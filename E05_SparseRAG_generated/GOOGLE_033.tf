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

variable "domain_root" {
  type        = string
  description = "The domain root for the load balancer"
}

variable "health_check_port" {
  type        = number
  description = "The port to use for the health check"
}

variable "health_check_path" {
  type        = string
  description = "The path to use for the health check"
}

variable "backend_service_port" {
  type        = number
  description = "The port to use for the backend service"
}

variable "url_map_default_service" {
  type        = string
  description = "The default service to use for the URL map"
}

resource "google_compute_health_check" "self" {
  name                = "${var.name}-health-check"
  check_interval_sec  = 10
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "self" {
  name        = "${var.name}-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.self.self_link]
}

resource "google_compute_url_map" "self" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.self.self_link

  host_rule {
    hosts        = [var.domain_root]
    service      = google_compute_backend_service.self.self_link
  }

  path_matcher {
    name            = "all-paths"
    default_service = google_compute_backend_service.self.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.self.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "self" {
  name    = "${var.name}-target-http-proxy"
  url_map = google_compute_url_map.self.self_link
}

resource "google_compute_global_forwarding_rule" "self" {
  name       = "${var.name}-global-forwarding-rule"
  target     = google_compute_target_http_proxy.self.self_link
  port_range = "80"
}

resource "google_compute_service_attachment" "self" {
  name        = "${var.name}-psc"
  description = "A service attachment to expose the internal load balancer for Private Service Connect"

  region = var.region

  domain_names = [var.domain_root]

  enable_proxy_protocol = false
  nat_subnets           = [google_compute_subnetwork.psc.id]
}

resource "google_compute_subnetwork" "psc" {
  name          = "${var.name}-psc-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  purpose       = "PRIVATE_SERVICE_CONNECT"
}