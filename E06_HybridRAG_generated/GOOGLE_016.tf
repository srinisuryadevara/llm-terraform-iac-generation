variable "name" {
  type        = string
  description = "The name of the load balancer"
}

variable "region" {
  type        = string
  description = "The region of the load balancer"
}

variable "project" {
  type        = string
  description = "The project ID of the load balancer"
}

variable "backend_service_name" {
  type        = string
  description = "The name of the backend service"
}

variable "health_check_name" {
  type        = string
  description = "The name of the health check"
}

variable "url_map_name" {
  type        = string
  description = "The name of the URL map"
}

variable "target_pool_name" {
  type        = string
  description = "The name of the target pool"
}

variable "instance_group_name" {
  type        = string
  description = "The name of the instance group"
}

variable "instance_group_zone" {
  type        = string
  description = "The zone of the instance group"
}

variable "port" {
  type        = number
  description = "The port number of the backend service"
}

variable "port_name" {
  type        = string
  description = "The name of the port"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.default.self_link
  }

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_url_map" "default" {
  name            = var.url_map_name
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
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}

resource "google_compute_health_check" "default" {
  name                = var.health_check_name
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port = var.port
  }
}

resource "google_compute_instance_group" "default" {
  name        = var.instance_group_name
  zone        = var.instance_group_zone
  instances   = []
  depends_on  = [google_compute_instance.default]
}

resource "google_compute_instance" "default" {
  name         = "instance"
  machine_type = "f1-micro"
  zone         = var.instance_group_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
  }
}