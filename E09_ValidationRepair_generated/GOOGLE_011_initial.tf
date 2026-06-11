provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_health_check" "default" {
  name                = "default-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  tcp_health_check {
    port = 80
  }
}

resource "google_compute_instance_template" "default" {
  name           = "default-instance-template"
  machine_type   = var.machine_type
  can_ip_forward = false

  disk {
    source_image = var.source_image
  }

  network_interface {
    network = var.network
  }

  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }
}

resource "google_compute_target_pool" "default" {
  name = "default-target-pool"

  health_checks = [
    google_compute_health_check.default.name,
  ]
}

resource "google_compute_instance_group_manager" "default" {
  name = "default-instance-group-manager"

  base_instance_name = "default-instance"
  instance_template  = google_compute_instance_template.default.self_link
  target_pools       = [google_compute_target_pool.default.self_link]
  target_size        = 1
}

resource "google_compute_autoscaler" "default" {
  name   = "default-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.self_link

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

variable "service_account_email" {
  type        = string
  sensitive   = true
}

variable "service_account_scopes" {
  type        = list(string)
  sensitive   = true
}

variable "zone" {
  type        = string
  sensitive   = true
}