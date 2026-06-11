variable "name" {
  type        = string
  description = "The name of the load balancer"
}

variable "region" {
  type        = string
  description = "The region of the load balancer"
}

variable "domain_root" {
  type        = string
  description = "The domain root of the load balancer"
}

variable "project_id" {
  type        = string
  description = "The project ID of the load balancer"
}

variable "health_check_port" {
  type        = number
  description = "The port of the health check"
}

variable "health_check_path" {
  type        = string
  description = "The path of the health check"
}

variable "backend_service_port" {
  type        = number
  description = "The port of the backend service"
}

variable "url_map_default_service" {
  type        = string
  description = "The default service of the URL map"
}

variable "url_map_host_rule_hosts" {
  type        = list(string)
  description = "The hosts of the URL map host rule"
}

variable "url_map_path_matcher_path" {
  type        = string
  description = "The path of the URL map path matcher"
}

resource "random_id" "tf_prefix" {
  byte_length = 8
}

resource "google_compute_health_check" "self" {
  name                = "${var.name}-health-check-${random_id.tf_prefix.hex}"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "self" {
  name                  = "${var.name}-backend-service-${random_id.tf_prefix.hex}"
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  enable_cdn            = false
  health_checks         = [google_compute_health_check.self.self_link]
  load_balancing_scheme = "INTERNAL"
}

resource "google_compute_url_map" "self" {
  name            = "${var.name}-url-map-${random_id.tf_prefix.hex}"
  default_service = google_compute_backend_service.self.self_link

  host_rule {
    hosts        = var.url_map_host_rule_hosts
    service      = google_compute_backend_service.self.self_link
  }

  path_matcher {
    name            = "${var.name}-path-matcher-${random_id.tf_prefix.hex}"
    default_service = google_compute_backend_service.self.self_link

    path_rule {
      paths   = [var.url_map_path_matcher_path]
      service = google_compute_backend_service.self.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "self" {
  name    = "${var.name}-target-http-proxy-${random_id.tf_prefix.hex}"
  url_map = google_compute_url_map.self.self_link
}

resource "google_compute_global_forwarding_rule" "self" {
  name       = "${var.name}-global-forwarding-rule-${random_id.tf_prefix.hex}"
  target     = google_compute_target_http_proxy.self.self_link
  port_range = "80"
}

resource "google_compute_service_attachment" "self" {
  name        = "${var.name}-psc-${random_id.tf_prefix.hex}"
  description = "A service attachment to expose the internal load balancer for Private Service Connect"

  region = var.region

  domain_names = [var.domain_root]

  enable_proxy_protocol = false
  nat_subnets           = [google_compute_subnetwork.psc.id]
}

resource "google_compute_subnetwork" "psc" {
  name          = "${var.name}-psc-subnetwork-${random_id.tf_prefix.hex}"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.psc.id
  purpose       = "PRIVATE_SERVICE_CONNECT"
}

resource "google_compute_network" "psc" {
  name                    = "${var.name}-psc-network-${random_id.tf_prefix.hex}"
  auto_create_subnetworks = false
}