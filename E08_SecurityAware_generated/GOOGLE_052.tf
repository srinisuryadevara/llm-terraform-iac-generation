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
  description = "The region to deploy to"
}

variable "vpc_network" {
  type        = string
  description = "The VPC network to use"
}

variable "subnet_cidr" {
  type        = string
  description = "The subnet CIDR to use"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
}

variable "instance_group" {
  type        = string
  description = "The instance group to use"
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
  default     = "1.2"
}

resource "google_compute_network" "vpc_network" {
  name                    = "vpc-network"
  auto_create_subnetworks = false
  project                 = var.project_id
  tags                    = ["vpc-network"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
  region        = var.region
  tags          = ["subnet"]
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-firewall"
  network = google_compute_network.vpc_network.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["ssh-target"]
  tags          = ["ssh-firewall"]
}

resource "google_compute_instance_group" "instance_group" {
  name        = var.instance_group
  project     = var.project_id
  zone        = "${var.region}-a"
  network     = google_compute_network.vpc_network.id
  subnetwork  = google_compute_subnetwork.subnet.id
  tags        = ["instance-group"]
}

resource "google_compute_backend_service" "backend_service" {
  name        = "backend-service"
  project     = var.project_id
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.instance_group.id
  }

  health_checks = [google_compute_health_check.health_check.id]
  tags          = ["backend-service"]
}

resource "google_compute_health_check" "health_check" {
  name                = "health-check"
  project             = var.project_id
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }

  tags = ["health-check"]
}

resource "google_compute_url_map" "url_map" {
  name            = "url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.backend_service.id

  host_rule {
    hosts        = var.url_map_host_rule_hosts
    service      = google_compute_backend_service.backend_service.id
  }

  path_matcher {
    name            = "path-matcher"
    default_service = google_compute_backend_service.backend_service.id

    path_rule {
      paths   = [var.url_map_path_matcher_path]
      service = google_compute_backend_service.backend_service.id
    }
  }

  tags = ["url-map"]
}

resource "google_compute_target_https_proxy" "target_https_proxy" {
  name             = "target-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_ssl_certificate.ssl_certificate.id]
  tags             = ["target-https-proxy"]
}

resource "google_compute_ssl_certificate" "ssl_certificate" {
  name        = "ssl-certificate"
  project     = var.project_id
  private_key = file("~/.ssh/ssl_private_key")
  certificate = file("~/.ssh/ssl_certificate")
  tags        = ["ssl-certificate"]
}

resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "global-forwarding-rule"
  project    = var.project_id
  port_range = "443"
  target     = google_compute_target_https_proxy.target_https_proxy.id
  tags       = ["global-forwarding-rule"]
}