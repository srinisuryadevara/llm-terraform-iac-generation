# VARIABLES
variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
variable "instance_name" {
  default = "managed-instance"
}
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
variable "cpu_utilization_target" {
  default = 0.5
}

# PROVIDERS
provider "google" {
  version = "~> 4.0"
  region  = var.region
}

# HEALTH CHECK
resource "google_compute_health_check" "default" {
  name                = "health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# INSTANCE TEMPLATE
resource "google_compute_instance_template" "default" {
  name           = var.instance_name
  machine_type   = var.machine_type
  region         = var.region
  can_ip_forward = false

  disk {
    source_image = var.image
  }

  network_interface {
    network = "default"
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      apt-get update
      apt-get install -y nginx
      service nginx start
    EOF
  }

  lifecycle {
    create_before_destroy = true
  }
}

# INSTANCE GROUP MANAGER
resource "google_compute_instance_group_manager" "default" {
  name               = var.instance_name
  zone               = var.zone
  instance_template  = google_compute_instance_template.default.self_link
  target_size        = var.min_replicas
  base_instance_name = var.instance_name

  auto_healing_policies {
    health_check      = google_compute_health_check.default.self_link
    initial_delay_sec = 300
  }
}

# AUTOSCALING
resource "google_compute_autoscaler" "default" {
  name   = var.instance_name
  zone   = var.zone
  target = google_compute_instance_group_manager.default.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }
}