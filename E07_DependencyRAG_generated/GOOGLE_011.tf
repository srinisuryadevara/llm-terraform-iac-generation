variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
variable "instance_template_name" {}
variable "instance_group_name" {}
variable "autoscaling_min_replicas" {
  default = 1
}
variable "autoscaling_max_replicas" {
  default = 5
}
variable "health_check_name" {}
variable "health_check_port" {
  default = 80
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
      echo "Hello World!" > index.html
      python3 -m http.server 80 &
    EOF
  }
}

resource "google_compute_health_check" "health_check" {
  name                = var.health_check_name
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = var.health_check_port
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.instance_group_manager.self_link

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
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

resource "google_compute_instance_group" "instance_group" {
  name               = var.instance_group_name
  zone               = var.zone
  instances          = []
  named_port {
    name = "http"
    port = 80
  }
}