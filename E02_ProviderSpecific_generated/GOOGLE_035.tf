provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_group_name" {
  type = string
}

variable "instance_template_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "image" {
  type = string
}

variable "min_replicas" {
  type = number
}

variable "max_replicas" {
  type = number
}

variable "cooldown_period" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "health_check_port" {
  type = number
}

resource "google_compute_instance_template" "instance_template" {
  name           = var.instance_template_name
  machine_type    = var.machine_type
  can_ip_forward  = false

  disk {
    source_image = var.image
  }

  network_interface {
    network = "default"
  }
}

resource "google_compute_health_check" "health_check" {
  name               = "health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_instance_group_manager" "instance_group" {
  name               = var.instance_group_name
  base_instance_name = "instance"
  zone               = "${var.region}-a"
  version {
    instance_template = google_compute_instance_template.instance_template.self_link
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.self_link
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "autoscaler"
  zone  = "${var.region}-a"
  target = google_compute_instance_group_manager.instance_group.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    metric {
      name   = "cpu"
      target = 0.5
      type   = "utilization"
    }
  }
}