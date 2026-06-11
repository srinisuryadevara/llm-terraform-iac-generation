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

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "redis_instance_name" {
  type = string
}

variable "redis_instance_tier" {
  type = string
}

variable "redis_instance_memory_size_gb" {
  type = number
}

locals {
  config = {
    project               = var.project
    region                = var.region
    vpc_name              = var.vpc_name
    subnet_name           = var.subnet_name
    redis_instance_name   = var.redis_instance_name
    redis_instance_tier   = var.redis_instance_tier
    redis_instance_memory_size_gb = var.redis_instance_memory_size_gb
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
}

resource "google_redis_instance" "cache" {
  name                    = local.config.redis_instance_name
  memory_size_gb          = local.config.redis_instance_memory_size_gb
  project                 = local.config.project
  location_id             = "${local.config.region}-c"
  tier                    = local.config.redis_instance_tier
  authorized_network      = google_compute_network.vpc.id
}

output "redis_instance_host" {
  value = google_redis_instance.cache.host
}