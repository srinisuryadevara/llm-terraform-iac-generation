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
variable "min_replicas" {
  default = 1
}
variable "max_replicas" {
  default = 5
}
variable "cpu_utilization_target" {
  default = 0.5
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

resource "google_compute_health_check" "default" {
  name                = "health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  unhealthy_threshold = 2

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_autoscaler" "default" {
  name   = "autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }
}

resource "google_compute_instance_group_manager" "default" {
  name               = "instance-group-manager"
  zone               = var.zone
  instance_template  = google_compute_instance_template.default.id
  target_size        = var.min_replicas
  base_instance_name = "instance"

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }
}