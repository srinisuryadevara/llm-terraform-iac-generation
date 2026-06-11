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

variable "health_check_name" {
  type = string
}

variable "health_check_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

resource "google_compute_health_check" "default" {
  name                = var.health_check_name
  check_interval_sec  = 5
  timeout_sec        = 5
  unhealthy_threshold = 2

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_instance_template" "default" {
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
    startup-script = "echo 'Hello World!' > index.html; python3 -m http.server 8080 &"
  }
}

resource "google_compute_instance_group_manager" "default" {
  name               = var.instance_group_name
  base_instance_name = "instance"
  zone               = "${var.region}-a"

  version {
    instance_template = google_compute_instance_template.default.id
  }

  target_pools = []
  target_size  = var.min_replicas

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "default" {
  name   = var.instance_group_name
  zone  = "${var.region}-a"
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