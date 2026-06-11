provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_vpc" "redis_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_subnetwork" "redis_subnetwork" {
  name          = var.subnetwork_name
  ip_cidr_range = var.subnetwork_cidr
  region        = var.region
  network       = google_vpc.redis_vpc.id
}

resource "google_redis_instance" "redis_instance" {
  name           = var.redis_instance_name
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size

  redis_version = var.redis_version

  authorized_network = google_vpc.redis_vpc.id
  labels             = var.labels
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

variable "subnetwork_name" {
  type = string
}

variable "subnetwork_cidr" {
  type = string
}

variable "redis_instance_name" {
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

variable "labels" {
  type = map(string)
}