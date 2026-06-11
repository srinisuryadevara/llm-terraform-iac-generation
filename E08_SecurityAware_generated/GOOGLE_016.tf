provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy the resources"
}

variable "vpc_network" {
  type        = string
  description = "The name of the VPC network"
}

variable "allowed_source_cidr" {
  type        = string
  description = "The allowed source CIDR for the firewall rule"
}

variable "instance_group_name" {
  type        = string
  description = "The name of the instance group"
}

variable "instance_group_zone" {
  type        = string
  description = "The zone of the instance group"
}

variable "health_check_port" {
  type        = number
  description = "The port to use for the health check"
}

variable "health_check_path" {
  type        = string
  description = "The path to use for the health check"
}

variable "url_map_default_service" {
  type        = string
  description = "The default service to use for the URL map"
}

variable "url_map_host_rule_hosts" {
  type        = list(string)
  description = "The hosts to use for the URL map host rule"
}

variable "url_map_path_matcher_path" {
  type        = string
  description = "The path to use for the URL map path matcher"
}

variable "url_map_path_matcher_service" {
  type        = string
  description = "The service to use for the URL map path matcher"
}

variable "tls_min_version" {
  type        = string
  description = "The minimum TLS version to use"
}

resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_network
  auto_create_subnetworks = false
  project                 = var.project_id
  tags                    = ["network", "vpc"]
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
  region        = var.region
  tags          = ["subnetwork", "vpc"]
}

resource "google_compute_instance_group" "instance_group" {
  name        = var.instance_group_name
  zone        = var.instance_group_zone
  project     = var.project_id
  network     = google_compute_network.vpc_network.id
  subnetwork  = google_compute_subnetwork.subnetwork.id
  tags        = ["instance-group", "vpc"]
}

resource "google_compute_health_check" "health_check" {
  name                = "health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  unhealthy_threshold = 2
  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
  project = var.project_id
  tags    = ["health-check", "vpc"]
}

resource "google_compute_backend_service" "backend_service" {
  name        = "backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [
    google_compute_health_check.health_check.id
  ]
  backend {
    group = google_compute_instance_group.instance_group.id
  }
  project = var.project_id
  tags    = ["backend-service", "vpc"]
}

resource "google_compute_url_map" "url_map" {
  name            = "url-map"
  default_service = var.url_map_default_service
  host_rule {
    hosts        = var.url_map_host_rule_hosts
    service      = var.url_map_default_service
  }
  path_matcher {
    name            = "path-matcher"
    default_service = var.url_map_default_service
    path_rule {
      paths   = [var.url_map_path_matcher_path]
      service = var.url_map_path_matcher_service
    }
  }
  project = var.project_id
  tags    = ["url-map", "vpc"]
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy"
  url_map = google_compute_url_map.url_map.id
  project = var.project_id
  tags    = ["http-proxy", "vpc"]
}

resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "global-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
  project    = var.project_id
  tags       = ["global-forwarding-rule", "vpc"]
}

resource "google_compute_firewall" "firewall" {
  name    = "firewall"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = [var.allowed_source_cidr]
  project       = var.project_id
  tags          = ["firewall", "vpc"]
}

resource "google_compute_ssl_policy" "ssl_policy" {
  name            = "ssl-policy"
  min_tls_version = var.tls_min_version
  project         = var.project_id
  tags            = ["ssl-policy", "vpc"]
}