variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
variable "instance_template_name" {}
variable "instance_template_description" {}
variable "machine_type" {
  default = "e2-medium"
}
variable "image" {
  default = "debian-cloud/debian-9"
}
variable "health_check_name" {}
variable "health_check_description" {}
variable "health_check_port" {
  default = 80
}
variable "health_check_path" {
  default = "/"
}
variable "health_check_timeout" {
  default = 5
}
variable "health_check_interval" {
  default = 10
}
variable "health_check_unhealthy_threshold" {
  default = 2
}
variable "health_check_healthy_threshold" {
  default = 2
}
variable "autoscaling_min_replicas" {
  default = 1
}
variable "autoscaling_max_replicas" {
  default = 10
}
variable "autoscaling_cooldown_period" {
  default = 60
}
variable "autoscaling_cpu_utilization_target" {
  default = 0.5
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance_template" "instance_template" {
  name        = var.instance_template_name
  description = var.instance_template_description

  machine_type = var.machine_type
  disk {
    source_image = var.image
  }
  network_interface {
    network = google_compute_network.network.self_link
  }
  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      service nginx start
    EOF
  }
}

resource "google_compute_target_pool" "target_pool" {
  name = "target-pool"

  health_checks = [
    google_compute_http_health_check.health_check.self_link,
  ]
}

resource "google_compute_http_health_check" "health_check" {
  name                = var.health_check_name
  description         = var.health_check_description
  port                = var.health_check_port
  request_path        = var.health_check_path
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  unhealthy_threshold = var.health_check_unhealthy_threshold
  healthy_threshold   = var.health_check_healthy_threshold
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.instance_group_manager.self_link

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = var.autoscaling_cooldown_period

    cpu_utilization {
      target = var.autoscaling_cpu_utilization_target
    }
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name = "instance-group-manager"

  zone               = var.zone
  instance_template  = google_compute_instance_template.instance_template.self_link
  target_pools       = [google_compute_target_pool.target_pool.self_link]
  target_size        = 1
  base_instance_name = "instance"
}

resource "google_compute_network" "network" {
  name                    = "network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.network.self_link
  region        = var.region
}