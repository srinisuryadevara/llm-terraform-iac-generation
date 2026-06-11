provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  labels = {
    environment = "production"
    application = "redis"
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  labels = {
    environment = "production"
    application = "redis"
  }
}

resource "google_memorystore_redis_instance" "redis" {
  name           = var.redis_name
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size

  redis_version = var.redis_version

  authorized_network = google_compute_network.vpc.id
  labels = {
    environment = "production"
    application = "redis"
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "redis_name" {
  type = string
}

variable "redis_tier" {
  type = string
}

variable "redis_memory_size" {
  type = number
}

variable "redis_version" {
  type = string
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "redis_instance_id" {
  value = google_memorystore_redis_instance.redis.id
}

output "redis_instance_host" {
  value = google_memorystore_redis_instance.redis.host
}

output "redis_instance_port" {
  value = google_memorystore_redis_instance.redis.port
}