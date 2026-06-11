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
variable "min_replicas" {
  default = 1
}
variable "max_replicas" {
  default = 5
}
variable "cooldown_period" {
  default = 60
}
variable "health_check_name" {}
variable "health_check_port" {
  default = 80
}

provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project_id
}

resource "google_compute_instance_template" "default" {
  name         = var.instance_template_name
  machine_type = var.machine_type
  region       = var.region

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"
  }

  tags = ["health-check", "ssh"]
}

resource "google_compute_health_check" "default" {
  name                = var.health_check_name
  check_interval_sec  = 5
  timeout_sec         = 5
  unhealthy_threshold = 2
  http_health_check {
    port = var.health_check_port
  }
}

resource "google_compute_autoscaler" "default" {
  name   = var.instance_group_name
  zone   = var.zone
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_group_manager" "default" {
  name               = var.instance_group_name
  zone               = var.zone
  instance_template  = google_compute_instance_template.default.id
  target_size        = var.min_replicas
  base_instance_name = var.instance_group_name
}

resource "google_compute_target_pool" "default" {
  name = var.instance_group_name

  health_checks = [
    google_compute_health_check.default.id,
  ]
}

resource "google_compute_instance_group" "default" {
  name        = var.instance_group_name
  zone        = var.zone
  instances   = []
  target_pools = [
    google_compute_target_pool.default.id,
  ]
}