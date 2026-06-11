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

  network_interface {
    network = var.network
  }

  disk {
    source_image = var.image
  }

  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }
}

resource "google_compute_instance_group_manager" "default" {
  name               = "instance-group-manager"
  instance_template  = google_compute_instance_template.default.self_link
  base_instance_name = "instance-group"
  zone               = var.zone

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

variable "network" {
  type        = string
  sensitive   = true
}

variable "image" {
  type        = string
  sensitive   = true
}

variable "zone" {
  type        = string
  sensitive   = true
}