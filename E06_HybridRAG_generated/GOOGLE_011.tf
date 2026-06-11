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
  default = 10
}
variable "cooldown_period" {
  default = 60
}
variable "health_check_path" {
  default = "/"
}
variable "health_check_port" {
  default = 80
}

# PROVIDERS
provider "google" {
  version = "~>2.0"
  region  = var.region
}

# RESOURCES
resource "google_compute_instance_template" "default" {
  name         = var.instance_template_name
  machine_type = var.machine_type
  disk {
    source_image = var.image
  }
  network_interface {
    network = "default"
  }
  tags = ["health-check", "ssh"]
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
}

resource "google_compute_target_pool" "default" {
  name = "target-pool"
}

resource "google_compute_forwarding_rule" "default" {
  name       = "forwarding-rule"
  region     = var.region
  target     = google_compute_target_pool.default.id
  port_range = "80"
}