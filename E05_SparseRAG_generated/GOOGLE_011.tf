variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
variable "instance_group_name" {}
variable "instance_template_name" {}
variable "machine_type" {
  default = "e2-medium"
}
variable "image" {
  default = "debian-cloud/debian-9"
}
variable "network" {
  default = "default"
}
variable "health_check_path" {
  default = "/healthcheck"
}
variable "health_check_port" {
  default = 80
}
variable "autoscaling_min_replicas" {
  default = 1
}
variable "autoscaling_max_replicas" {
  default = 5
}
variable "autoscaling_cooldown_period" {
  default = 60
}
variable "autoscaling_cpu_utilization_target" {
  default = 0.5
}

provider "google" {
  version = "~> 3.0"
  region  = var.region
}

resource "google_compute_instance_template" "default" {
  name           = var.instance_template_name
  machine_type   = var.machine_type
  can_ip_forward = false

  disk {
    source_image = var.image
  }

  network_interface {
    network = var.network
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      echo "Hello World!" > /var/www/html/index.html
    EOF
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
    cooldown_period = var.autoscaling_cooldown_period

    cpu_utilization {
      target = var.autoscaling_cpu_utilization_target
    }
  }
}

resource "google_compute_instance_group_manager" "default" {
  name               = var.instance_group_name
  zone               = var.zone
  instance_template  = google_compute_instance_template.default.id
  target_pools       = [google_compute_target_pool.default.id]
  target_size        = 1
  base_instance_name = "instance"
}