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
  project     = var.project_id
  region      = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  type        = string
  default     = "memorystore-vpc"
}

variable "subnet_name" {
  type        = string
  default     = "memorystore-subnet"
}

variable "redis_instance_name" {
  type        = string
  default     = "memorystore-redis"
}

variable "redis_tier" {
  type        = string
  default     = "STANDARD_HA"
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_redis_instance" "redis" {
  name           = var.redis_instance_name
  tier           = var.redis_tier
  memory_size_gb = 1

  redis_config {
    max_memory_policy = "VOLATILE_LRU"
  }

  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "allow_redis" {
  name    = "allow-redis"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
}

resource "google_compute_address" "redis_ip" {
  name = "redis-ip"
  region = var.region
}

resource "google_compute_global_address" "redis_global_ip" {
  name = "redis-global-ip"
}

output "redis_instance_name" {
  value = google_redis_instance.redis.name
}

output "redis_instance_id" {
  value = google_redis_instance.redis.id
}

output "redis_host" {
  value = google_compute_address.redis_ip.address
}

output "redis_port" {
  value = 6379
}