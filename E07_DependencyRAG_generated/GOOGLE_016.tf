variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "port" {
  type = number
}

variable "health_check_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "backend_service_port" {
  type = number
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = "${var.name}-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_url_map" "default" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.default.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.default.self_link
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.name}-global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}

resource "google_compute_health_check" "default" {
  name                = "${var.name}-health-check"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "instance_group" {
  name        = "${var.name}-instance-group-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.default.instance_group
  }

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_instance_group_manager" "default" {
  name               = "${var.name}-instance-group-manager"
  instance_template  = google_compute_instance_template.default.self_link
  base_instance_name = "${var.name}-instance"
  target_size        = 1
}

resource "google_compute_instance_template" "default" {
  name           = "${var.name}-instance-template"
  machine_type   = "f1-micro"
  can_ip_forward = false

  network_interface {
    network = "default"
  }

  disk {
    source_image = "debian-cloud/debian-9"
  }

  metadata = {
    startup-script = <<-EOF
              #! /bin/bash
              apt-get update
              apt-get install -y nginx
              service nginx start
              EOF
  }

  lifecycle {
    create_before_destroy = true
  }
}