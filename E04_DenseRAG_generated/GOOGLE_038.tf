terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.state_bucket
  }
}

provider "google" {
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  project     = var.project
  region      = var.region
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "redis_instance_name" {
  type = string
}

variable "redis_instance_tier" {
  type = string
}

locals {
  config = {
    project     = var.project
    region      = var.region
    network     = var.network
    subnetwork  = var.subnetwork
    redis_instance_name = var.redis_instance_name
    redis_instance_tier = var.redis_instance_tier
  }
}

resource "google_compute_network" "vpc" {
  name                    = "memorystore-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "memorystore-subnet"
  ip_cidr_range = "10.0.0.0/28"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_redis_instance" "cache" {
  name                    = local.config.redis_instance_name
  memory_size_gb          = 1
  project                 = local.config.project
  location_id             = "${local.config.region}-c"
  tier                    = local.config.redis_instance_tier
  authorized_network      = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow-redis" {
  name    = "allow-redis"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
}