terraform {
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
  }
}

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
variable "instance_template" {}
variable "autoscaling_min_replicas" {
  default = 1
}
variable "autoscaling_max_replicas" {
  default = 5
}
variable "health_check_path" {
  default = "/"
}
variable "health_check_port" {
  default = 80
}

resource "google_compute_instance_template" "default" {
  name         = "instance-template"
  machine_type = "e2-medium"
  region       = var.region

  disk {
    source_image = "debian-cloud/debian-9"
  }

  network_interface {
    network = "default"
  }
}

resource "google_compute_target_pool" "default" {
  name = "target-pool"

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_http_health_check" "default" {
  name                = "http-health-check"
  request_path        = var.health_check_path
  port                = var.health_check_port
  check_interval_sec  = 1
  timeout_sec         = 1
  unhealthy_threshold = 10
}

resource "google_compute_autoscaler" "default" {
  name   = "autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_group_manager" "default" {
  name               = "instance-group-manager"
  zone               = var.zone
  instance_template  = google_compute_instance_template.default.id
  target_pools       = [google_compute_target_pool.default.name]
  target_size        = 1
  base_instance_name = "instance"
}

resource "google_compute_health_check" "default" {
  name                = "health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}