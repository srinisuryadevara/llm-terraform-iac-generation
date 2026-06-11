terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
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
  default     = "us-central1"
}

variable "bucket_name" {
  type        = string
  sensitive   = true
}

variable "vpc_name" {
  type        = string
}

variable "subnet_name" {
  type        = string
}

variable "memorystore_tier" {
  type        = string
  default     = "BASIC"
}

variable "memorystore_size" {
  type        = number
  default     = 1
}

locals {
  config = {
    project     = var.project_id
    region      = var.region
    vpc_name    = var.vpc_name
    subnet_name = var.subnet_name
    tier        = var.memorystore_tier
    size        = var.memorystore_size
  }
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

resource "google_redis_instance" "memorystore" {
  name                    = "memorystore"
  tier                    = local.config.tier
  memory_size_gb          = local.config.size
  project                 = local.config.project
  location_id             = "${local.config.region}-c"
  authorized_network      = google_compute_network.vpc.id
}

output "memorystore_host" {
  value = google_redis_instance.memorystore.host
}