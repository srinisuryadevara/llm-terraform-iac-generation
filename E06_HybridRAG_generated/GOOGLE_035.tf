# VARIABLES
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
variable "health_check_interval" {
  default = 10
}
variable "health_check_timeout" {
  default = 5
}
variable "health_check_unhealthy_threshold" {
  default = 2
}
variable "health_check_healthy_threshold" {
  default = 2
}

# PROVIDERS
provider "google" {
  version = "~> 4.0"
  region  = var.region
}

# RESOURCES
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
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      service nginx start
    EOF
  }
}

resource "google_compute_health_check" "default" {
  name                = "health-check"
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  unhealthy_threshold = var.health_check_unhealthy_threshold
  healthy_threshold   = var.health_check_healthy_threshold

  http_health_check {
    port = 80
  }
}

resource "google_compute_autoscaler" "default" {
  name   = "autoscaler"
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
  base_instance_name = "instance"

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }
}

resource "google_compute_instance_group" "default" {
  name               = var.instance_group_name
  zone               = var.zone
  instances          = []
  named_port {
    name = "http"
    port = 80
  }
}