terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.57"
    }
  }
}

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
  default     = "europe-west1"
}

variable "network" {
  type        = string
  default     = "default"
}

variable "subnetwork" {
  type        = string
  default     = "default"
}

variable "redis_instance_name" {
  type        = string
  default     = "redis"
}

variable "redis_memory_size_gb" {
  type        = number
  default     = 1
}

variable "redis_tier" {
  type        = string
  default     = "BASIC"
}

resource "google_compute_network" "vpc" {
  name                    = "private-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_compute_firewall" "allow_redis" {
  name    = "allow-redis"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
}

resource "google_redis_instance" "cache" {
  name                    = var.redis_instance_name
  memory_size_gb          = var.redis_memory_size_gb
  project                 = var.project_id
  location_id             = "${var.region}-c"
  tier                    = var.redis_tier
  authorized_network      = google_compute_network.vpc.id
}

output "redis_instance_name" {
  value = google_redis_instance.cache.name
}

output "redis_instance_host" {
  value = google_redis_instance.cache.host
}

output "redis_instance_port" {
  value = google_redis_instance.cache.port
}