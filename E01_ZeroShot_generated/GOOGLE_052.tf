provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "health_check_port" {
  type = number
}

variable "backend_service_port" {
  type = number
}

variable "url_map_default_service" {
  type = string
}

variable "url_map_path_matcher_path" {
  type = string
}

resource "google_compute_backend_service" "default" {
  name        = "load-balancer-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  name               = "load-balancer-health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port         = var.health_check_port
    request_path = "/"
  }
}

resource "google_compute_url_map" "default" {
  name            = "load-balancer-url-map"
  default_service = var.url_map_default_service

  host_rule {
    hosts        = ["*"]
    service      = var.url_map_default_service
  }

  path_matcher {
    name            = "path-matcher"
    default_service = var.url_map_default_service

    path_rule {
      paths   = [var.url_map_path_matcher_path]
      service = var.url_map_default_service
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "load-balancer-target-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "load-balancer-global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}

resource "google_compute_backend_service" "instance_group" {
  name        = "load-balancer-backend-service-instance-group"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group          = google_compute_instance_group_manager.default.instance_group
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_instance_group_manager" "default" {
  name               = "load-balancer-instance-group-manager"
  instance_template  = google_compute_instance_template.default.id
  base_instance_name = "load-balancer-instance"
  target_size        = 1
}

resource "google_compute_instance_template" "default" {
  name           = "load-balancer-instance-template"
  machine_type   = "f1-micro"
  can_ip_forward = false

  network_interface {
    network = "default"
  }

  disk {
    source_image = "debian-cloud/debian-11"
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      apt-get update
      apt-get install -y nginx
      service nginx start
    EOF
  }
}