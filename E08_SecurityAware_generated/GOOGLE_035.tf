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
  tags = ["instance-group-health-check"]
}

resource "google_compute_instance_template" "default" {
  name           = "instance-template"
  machine_type   = var.machine_type
  can_ip_forward = false

  tags = ["instance-template"]

  disk {
    source_image = var.source_image
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    boot         = true
  }

  network_interface {
    network = var.network
  }

  metadata = {
    startup-script = file("${path.module}/startup-script.sh")
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_target_pool" "default" {
  name = "instance-group-target-pool"

  health_checks = [
    google_compute_health_check.default.id,
  ]

  tags = ["instance-group-target-pool"]
}

resource "google_compute_instance_group_manager" "default" {
  name               = "instance-group-manager"
  instance_template  = google_compute_instance_template.default.id
  target_pools       = [google_compute_target_pool.default.id]
  base_instance_name = "instance-group"
  target_size        = var.target_size

  tags = ["instance-group-manager"]

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "default" {
  name   = "instance-group-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }

  tags = ["instance-group-autoscaler"]
}

resource "google_compute_firewall" "default" {
  name    = "instance-group-firewall"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [var.allowed_cidr]
  target_tags   = ["instance-group"]

  tags = ["instance-group-firewall"]
}

variable "project_id" {
  type        = string
  description = "The ID of the project to deploy to"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "machine_type" {
  type        = string
  description = "The machine type to use for the instances"
}

variable "source_image" {
  type        = string
  description = "The source image to use for the instances"
}

variable "disk_size_gb" {
  type        = number
  description = "The size of the disk to use for the instances"
}

variable "disk_type" {
  type        = string
  description = "The type of disk to use for the instances"
}

variable "network" {
  type        = string
  description = "The network to use for the instances"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account to use for the instances"
}

variable "target_size" {
  type        = number
  description = "The target size of the instance group"
}

variable "zone" {
  type        = string
  description = "The zone to deploy to"
}

variable "max_replicas" {
  type        = number
  description = "The maximum number of replicas to use for the autoscaler"
}

variable "min_replicas" {
  type        = number
  description = "The minimum number of replicas to use for the autoscaler"
}

variable "cpu_utilization_target" {
  type        = number
  description = "The target CPU utilization for the autoscaler"
}

variable "allowed_cidr" {
  type        = string
  description = "The allowed CIDR range for the firewall"
}