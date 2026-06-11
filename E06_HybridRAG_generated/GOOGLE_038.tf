terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.57"
    }
  }
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.state_bucket
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "europe-west1"
}

variable "state_bucket" {
  type        = string
  sensitive   = true
}

variable "network" {
  type        = string
  default     = "default"
}

variable "ip_cidr_range" {
  type        = string
  default     = "10.9.0.0/28"
}

variable "memorystore_tier" {
  type        = string
  default     = "BASIC"
}

locals {
  config = {
    project     = var.project_id
    region      = var.region
    network     = var.network
    ip_cidr_range = var.ip_cidr_range
    memorystore_tier = var.memorystore_tier
  }
}

resource "google_storage_bucket" "code" {
  name     = "${var.project_id}_code"
  location = "EU"
}

resource "google_storage_bucket_object" "config_file" {
  name   = "config.json"
  content = jsonencode(local.config)
  bucket = google_storage_bucket.code.name
}

resource "google_vpc_network" "vpc" {
  name                    = "private-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "private-subnet"
  ip_cidr_range = var.ip_cidr_range
  network       = google_vpc_network.vpc.id
  region        = var.region
}

resource "google_redis_instance" "cache" {
  name                    = "redis"
  memory_size_gb          = 1
  project                 = var.project_id
  location_id             = "${var.region}-c"
  tier                    = var.memorystore_tier
  authorized_network      = google_compute_subnetwork.subnet.id
}

resource "google_compute_firewall" "allow_redis" {
  name    = "allow-redis"
  network = google_vpc_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
}

resource "google_compute_firewall" "deny_all" {
  name    = "deny-all"
  network = google_vpc_network.vpc.id

  deny {
    protocol = "all"
  }

  priority = 65534
  target_tags = ["redis"]
}