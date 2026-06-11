provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "instance_type" {
  type        = string
  description = "The type of instance to use"
}

variable "min_instances" {
  type        = number
  description = "The minimum number of instances to run"
}

variable "max_instances" {
  type        = number
  description = "The maximum number of instances to run"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The CIDR to allow SSH from"
}

variable "health_check_path" {
  type        = string
  description = "The path to check for health"
}

variable "health_check_port" {
  type        = number
  description = "The port to check for health"
}

resource "google_compute_instance_template" "template" {
  name           = "instance-template"
  machine_type   = var.instance_type
  can_ip_forward = false

  tags = {
    environment = "prod"
  }

  disk {
    source_image = "debian-cloud/debian-11"
    disk_size_gb = 50
    disk_type    = "pd-ssd"
    boot         = true
  }

  network_interface {
    network = google_compute_network.network.self_link
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

resource "google_compute_target_pool" "target_pool" {
  name = "target-pool"

  health_checks = [
    google_compute_http_health_check.health_check.name,
  ]
}

resource "google_compute_http_health_check" "health_check" {
  name                = "health-check"
  request_path        = var.health_check_path
  port                = var.health_check_port
  check_interval_sec  = 10
  timeout_sec         = 10
  unhealthy_threshold = 3
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "autoscaler"
  zone   = "${var.region}-a"
  target = google_compute_instance_group_manager.instance_group_manager.self_link

  autoscaling_policy {
    max_replicas    = var.max_instances
    min_replicas    = var.min_instances
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name = "instance-group-manager"

  version {
    instance_template = google_compute_instance_template.template.self_link
  }

  base_instance_name = "instance"
  target_pools       = [google_compute_target_pool.target_pool.self_link]
  target_size        = var.min_instances
}

resource "google_compute_network" "network" {
  name                    = "network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.network.self_link
  region        = var.region
}

resource "google_compute_firewall" "firewall" {
  name    = "firewall"
  network = google_compute_network.network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]

  target_tags = ["instance"]
}

resource "google_compute_firewall" "http_firewall" {
  name    = "http-firewall"
  network = google_compute_network.network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "https_firewall" {
  name    = "https-firewall"
  network = google_compute_network.network.self_link

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}