provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "instance_group_name" {
  type        = string
}

variable "instance_template_name" {
  type        = string
}

variable "machine_type" {
  type        = string
}

variable "image" {
  type        = string
}

variable "min_replicas" {
  type        = number
}

variable "max_replicas" {
  type        = number
}

variable "cooldown_period" {
  type        = number
}

variable "health_check_interval" {
  type        = string
}

variable "health_check_timeout" {
  type        = string
}

variable "health_check_unhealthy_threshold" {
  type        = number
}

variable "health_check_healthy_threshold" {
  type        = number
}

resource "google_compute_instance_template" "instance_template" {
  name           = var.instance_template_name
  machine_type   = var.machine_type
  can_ip_forward = false

  disk {
    source_image = var.image
  }

  network_interface {
    network = "default"
  }

  metadata = {
    startup-script = "#! /bin/bash\nsudo apt-get update\nsudo apt-get install -y nginx"
  }
}

resource "google_compute_health_check" "health_check" {
  name                = "health-check"
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  unhealthy_threshold = var.health_check_unhealthy_threshold
  healthy_threshold   = var.health_check_healthy_threshold

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = var.instance_group_name
  instance_template  = google_compute_instance_template.instance_template.self_link
  base_instance_name = var.instance_group_name
  target_size        = var.min_replicas

  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.self_link
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "autoscaler"
  target = google_compute_instance_group_manager.instance_group_manager.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = 0.5
    }
  }
}