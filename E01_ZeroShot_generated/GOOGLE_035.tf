provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_health_check" "default" {
  name                = "instance-group-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_instance_template" "default" {
  name           = "instance-template"
  machine_type   = var.machine_type
  can_ip_forward = false

  network_interface {
    network    = var.network_name
    subnetwork = var.subnetwork_name
  }

  disk {
    source_image = var.source_image
    boot         = true
  }

  lifecycle {
    create_before_destroy = true
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

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }
}

resource "google_compute_autoscaler" "default" {
  name   = "instance-group-autoscaler"
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

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnetwork_name" {
  type = string
}

variable "source_image" {
  type = string
}

variable "max_replicas" {
  type = number
}

variable "min_replicas" {
  type = number
}

variable "cpu_utilization_target" {
  type = number
}