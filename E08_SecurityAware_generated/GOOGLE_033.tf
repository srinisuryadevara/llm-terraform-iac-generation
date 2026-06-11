provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "vpc_network" {
  type        = string
  description = "VPC Network Name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH Source CIDR"
}

variable "instance_group_name" {
  type        = string
  description = "Instance Group Name"
}

variable "instance_group_zone" {
  type        = string
  description = "Instance Group Zone"
}

variable "instance_template_name" {
  type        = string
  description = "Instance Template Name"
}

variable "backend_service_name" {
  type        = string
  description = "Backend Service Name"
}

variable "url_map_name" {
  type        = string
  description = "URL Map Name"
}

variable "health_check_name" {
  type        = string
  description = "Health Check Name"
}

variable "target_pool_name" {
  type        = string
  description = "Target Pool Name"
}

variable "forwarding_rule_name" {
  type        = string
  description = "Forwarding Rule Name"
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_network
  auto_create_subnetworks = false
  project                 = var.project_id
  description             = "VPC Network for Load Balancer"
  tags                    = ["load-balancer", "vpc-network"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "load-balancer-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  project       = var.project_id
  region        = var.region
  description   = "Subnet for Load Balancer"
  tags          = ["load-balancer", "subnet"]
}

resource "google_compute_firewall" "ssh" {
  name    = "load-balancer-ssh"
  network = google_compute_network.vpc.id
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  description   = "Firewall rule for SSH access"
  tags          = ["load-balancer", "firewall", "ssh"]
}

resource "google_compute_instance_group" "instance_group" {
  name        = var.instance_group_name
  zone        = var.instance_group_zone
  project     = var.project_id
  description = "Instance Group for Load Balancer"
  tags        = ["load-balancer", "instance-group"]
}

resource "google_compute_instance_template" "instance_template" {
  name         = var.instance_template_name
  machine_type = "n1-standard-1"
  project      = var.project_id
  region       = var.region
  description  = "Instance Template for Load Balancer"
  tags         = ["load-balancer", "instance-template"]

  disk {
    source_image = "debian-cloud/debian-9"
    disk_size_gb = 50
    disk_type    = "pd-standard"
  }

  network_interface {
    network = google_compute_network.vpc.id
  }
}

resource "google_compute_health_check" "health_check" {
  name                = var.health_check_name
  project             = var.project_id
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  description         = "Health Check for Load Balancer"
  tags                = ["load-balancer", "health-check"]

  http_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = var.backend_service_name
  project               = var.project_id
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  enable_cdn            = false
  description           = "Backend Service for Load Balancer"
  tags                  = ["load-balancer", "backend-service"]

  backend {
    group = google_compute_instance_group.instance_group.id
  }

  health_checks = [google_compute_health_check.health_check.id]
}

resource "google_compute_url_map" "url_map" {
  name            = var.url_map_name
  project         = var.project_id
  default_service = google_compute_backend_service.backend_service.id
  description     = "URL Map for Load Balancer"
  tags            = ["load-balancer", "url-map"]

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.backend_service.id
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.backend_service.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.backend_service.id
    }
  }
}

resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "load-balancer-target-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.url_map.id
  description = "Target HTTP Proxy for Load Balancer"
  tags        = ["load-balancer", "target-http-proxy"]
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = var.forwarding_rule_name
  project    = var.project_id
  port_range = "80"
  target     = google_compute_target_http_proxy.target_http_proxy.id
  description = "Global Forwarding Rule for Load Balancer"
  tags        = ["load-balancer", "global-forwarding-rule"]
}