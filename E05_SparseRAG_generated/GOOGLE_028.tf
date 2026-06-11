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

variable "memorystore_size" {
  type        = number
  description = "The size of the Memorystore instance"
  default     = 1
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_network" "vpc" {
  name = var.vpc_name
}

data "google_compute_subnetwork" "subnet" {
  name = var.subnet_name
}

resource "google_redis_instance" "memorystore" {
  name           = "memorystore-instance"
  tier           = var.memorystore_tier
  memory_size_gb = var.memorystore_size

  location_id = var.region

  authorized_network = data.google_compute_network.vpc.id

  network = data.google_compute_network.vpc.id
  subnetwork = data.google_compute_subnetwork.subnet.id
}

output "memorystore_host" {
  value = google_redis_instance.memorystore.host
}

output "memorystore_port" {
  value = google_redis_instance.memorystore.port
}