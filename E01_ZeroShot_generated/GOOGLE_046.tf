provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_health_check" "default" {
  name                = "instance-group-health-check"
  check_interval_sec = 5
  timeout_sec         = 5
  tcp_health_check {
    port = 80
  }
}

resource "google_compute_instance_template" "default" {
  name           = "instance-template"
  machine_type   = var.machine_type
  can_ip_forward = false

  // Create a new boot disk from an image
  disk {
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
    google_compute_health_check.default.name,
  ]
}

resource "google_compute_instance_group_manager" "default" {
  name               = "instance-group-manager"
  base_instance_name = "instance-group"
  zone               = var.zone
  version {
    instance_template = google_compute_instance_template.default.self_link
  }

  target_pools = [
    google_compute_target_pool.default.self_link,
  ]

  auto_healing_policies {
    health_check      = google_compute_health_check.default.self_link
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "default" {
  name   = "instance-group-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 60

    cpu_utilization_policy {
      target = var.target_cpu_utilization
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

variable "source_image" {
  type = string
}

variable "network" {
  type = string
}

variable "zone" {
  type = string
}

variable "max_replicas" {
  type = number
}

variable "min_replicas" {
  type = number
}

variable "target_cpu_utilization" {
  type = number
}