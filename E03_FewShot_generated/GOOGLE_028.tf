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
  default     = "us-central1"
}

variable "vpc_name" {
  type        = string
}

variable "subnet_name" {
  type        = string
}

variable "redis_instance_name" {
  type        = string
}

variable "redis_instance_tier" {
  type        = string
  default     = "STANDARD_HA"
}

variable "redis_instance_memory_size_gb" {
  type        = number
  default     = 1
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

resource "google_redis_instance" "redis" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = var.redis_instance_memory_size_gb

  redis_version = "6.x"

  authorized_network = google_compute_network.vpc.id
}

output "redis_instance_host" {
  value = google_redis_instance.redis.host
}

output "redis_instance_port" {
  value = google_redis_instance.redis.port
}