variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "instance_template_name" {
  type = string
}

variable "instance_group_name" {
  type = string
}

variable "autoscaling_min_replicas" {
  type = number
}

variable "autoscaling_max_replicas" {
  type = number
}

variable "health_check_name" {
  type = string
}

variable "health_check_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance_template" "instance_template" {
  name           = var.instance_template_name
  machine_type   = "e2-medium"
  can_ip_forward = false

  disk {
    source_image = "debian-cloud/debian-9"
  }

  network_interface {
    network = "default"
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

resource "google_compute_health_check" "health_check" {
  name                = var.health_check_name
  check_interval_sec  = 5
  timeout_sec         = 5
  unhealthy_threshold = 2

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_instance_group_manager" "instance_group" {
  name               = var.instance_group_name
  zone               = var.zone
  instance_template  = google_compute_instance_template.instance_template.self_link
  target_size        = 1
  base_instance_name = "instance"

  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.self_link
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.instance_group.self_link

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}