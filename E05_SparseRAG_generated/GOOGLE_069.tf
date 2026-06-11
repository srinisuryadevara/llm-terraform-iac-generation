terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.57"
    }
  }
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

variable "redis_memory_size_gb" {
  type        = number
  default     = 1
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
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

resource "google_redis_instance" "redis" {
  name           = var.redis_instance_name
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size_gb

  authorized_network = google_compute_network.vpc.id
}

output "redis_instance_name" {
  value = google_redis_instance.redis.name
}

output "redis_instance_host" {
  value = google_redis_instance.redis.host
}

output "redis_instance_port" {
  value = google_redis_instance.redis.port
}