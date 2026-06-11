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
variable "network" {
  default = "default"
}
variable "health_check_path" {
  default = "/healthcheck"
}
variable "health_check_port" {
  default = 80
}
variable "autoscaling_min_replicas" {
  default = 1
}
variable "autoscaling_max_replicas" {
  default = 5
}
variable "autoscaling_cooldown_period" {
  default = 60
}

provider "google" {
  version = "~>2.0"
  region  = var.region
  project = var.project_id
}

resource "google_compute_instance_template" "default" {
  name           = var.instance_template_name
  machine_type   = var.machine_type
  can_ip_forward = false

  disk {
    source_image = var.image
  }

  network_interface {
    network = var.network
  }

  metadata = {
    startup-script = <<-EOF
              #!/bin/bash
              echo "Hello World!" > index.html
              python3 -m http.server 80 &
              EOF
  }
}

resource "google_compute_health_check" "default" {
  name                = "health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_instance_group_manager" "default" {
  name               = var.instance_group_name
  zone               = var.zone
  instance_template  = google_compute_instance_template.default.self_link
  target_size        = 1
  base_instance_name = "instance-group"

  auto_healing_policies {
    health_check      = google_compute_health_check.default.self_link
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "default" {
  name   = "autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.self_link

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = var.autoscaling_cooldown_period

    cpu_utilization {
      target = 0.5
    }
  }
}