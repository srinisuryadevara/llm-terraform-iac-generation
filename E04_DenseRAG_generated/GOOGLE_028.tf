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
  type = string
}

variable "region" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "memorystore_name" {
  type = string
}

variable "memorystore_tier" {
  type = string
}

locals {
  config = {
    project = var.project_id
    region = var.region
    vpc_name = var.vpc_name
    subnet_name = var.subnet_name
    memorystore_name = var.memorystore_name
    memorystore_tier = var.memorystore_tier
  }
}

resource "google_compute_network" "vpc" {
  name                    = local.config.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = local.config.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_redis_instance" "memorystore" {
  name                    = local.config.memorystore_name
  tier                    = local.config.memorystore_tier
  memory_size_gb          = 1
  project                 = var.project_id
  location_id             = "${var.region}-a"
  authorized_network      = google_compute_network.vpc.id
}

output "memorystore_host" {
  value = google_redis_instance.memorystore.host
}