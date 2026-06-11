provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_health_check" "default" {
  name                = "instance-group-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  unhealthy_threshold = 2
  http_health_check {
    port = 80
  }
}

resource "google_compute_instance_template" "default" {
  name           = "instance-template"
  machine_type   = var.machine_type
  can_ip_forward = false

  disks {
    source_image = var.source_image
  }

  network_interface {
    network = var.network
  }

  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }
}

resource "google_compute_target_pool" "default" {
  name = "instance-group-target-pool"

  health_checks = [
    google_compute_health_check.default.id,
  ]
}

resource "google_compute_instance_group_manager" "default" {
  name               = "instance-group-manager"
  instance_template  = google_compute_instance_template.default.id
  target_pools       = [google_compute_target_pool.default.id]
  base_instance_name = "instance-group"
}

resource "google_compute_autoscaler" "default" {
  name   = "instance-group-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "machine_type" {
  type        = string
  sensitive   = true
}

variable "source_image" {
  type        = string
  sensitive   = true
}

variable "network" {
  type        = string
  sensitive   = true
}

variable "zone" {
  type        = string
  sensitive   = true
}