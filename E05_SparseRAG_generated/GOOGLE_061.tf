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
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC to create the Memorystore instance in"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet to create the Memorystore instance in"
}

variable "memorystore_tier" {
  type        = string
  description = "The tier of the Memorystore instance"
  default     = "BASIC"
}

variable "redis_version" {
  type        = string
  description = "The version of Redis to use"
  default     = "REDIS_6_X"
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id
}

resource "google_redis_instance" "memorystore" {
  name           = "memorystore-instance"
  tier           = var.memorystore_tier
  memory_size_gb = 1

  redis_version = var.redis_version

  authorized_network = google_compute_network.vpc.id
}

output "memorystore_host" {
  value = google_redis_instance.memorystore.host
}