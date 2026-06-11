# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a private VPC
resource "google_vpc" "private_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  labels = {
    environment = "private"
    purpose     = "redis"
  }
}

# Create a private subnetwork
resource "google_subnetwork" "private_subnetwork" {
  name          = var.subnetwork_name
  ip_cidr_range = var.subnetwork_cidr
  network       = google_vpc.private_vpc.id
  labels = {
    environment = "private"
    purpose     = "redis"
  }
}

# Create a Memorystore Redis instance
resource "google_memorystore_instance" "redis_instance" {
  name           = var.redis_instance_name
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size

  redis_version = var.redis_version

  authorized_network = google_vpc.private_vpc.id
  labels = {
    environment = "private"
    purpose     = "redis"
  }
}

# Create a firewall rule to allow Redis traffic
resource "google_compute_firewall" "allow_redis" {
  name    = var.firewall_name
  network = google_vpc.private_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = [var.target_tags]
  labels = {
    environment = "private"
    purpose     = "redis"
  }
}

# Input variables
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
  default     = "private-vpc"
}

variable "subnetwork_name" {
  type        = string
  default     = "private-subnetwork"
}

variable "subnetwork_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "redis_instance_name" {
  type        = string
  default     = "redis-instance"
}

variable "redis_tier" {
  type        = string
  default     = "STANDARD_HA"
}

variable "redis_memory_size" {
  type        = number
  default     = 1
}

variable "redis_version" {
  type        = string
  default     = "REDIS_6_X"
}

variable "firewall_name" {
  type        = string
  default     = "allow-redis"
}

variable "target_tags" {
  type        = list(string)
  default     = ["redis-client"]
}

# Output key resource attributes
output "vpc_id" {
  value       = google_vpc.private_vpc.id
  description = "The ID of the private VPC"
}

output "subnetwork_id" {
  value       = google_subnetwork.private_subnetwork.id
  description = "The ID of the private subnetwork"
}

output "redis_instance_id" {
  value       = google_memorystore_instance.redis_instance.id
  description = "The ID of the Memorystore Redis instance"
}

output "redis_instance_host" {
  value       = google_memorystore_instance.redis_instance.host
  description = "The hostname of the Memorystore Redis instance"
}

output "redis_instance_port" {
  value       = google_memorystore_instance.redis_instance.port
  description = "The port of the Memorystore Redis instance"
}

output "firewall_id" {
  value       = google_compute_firewall.allow_redis.id
  description = "The ID of the firewall rule"
}