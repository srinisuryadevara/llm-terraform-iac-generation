provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR of the VPC"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The CIDR to allow SSH from"
}

variable "redis_instance_name" {
  type        = string
  description = "The name of the Redis instance"
}

variable "redis_instance_tier" {
  type        = string
  description = "The tier of the Redis instance"
}

resource "google_compute_network" "vpc" {
  name                    = "private-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1460
  tags                    = ["private-vpc"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "private-subnet"
  ip_cidr_range = var.vpc_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["private-subnet"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["allow-ssh"]
  tags          = ["allow-ssh"]
}

resource "google_redis_instance" "instance" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = 1
  region         = var.region
  labels         = {
    environment = "private"
  }
  authorized_network = google_compute_network.vpc.id
  transit_encryption_mode = "SERVER_AUTHENTICATION"
}

resource "google_service_account" "redis_sa" {
  account_id = "redis-sa"
}

resource "google_project_iam_binding" "redis_sa_binding" {
  project = var.project_id
  role    = "roles/redis.editor"
  members = [
    "serviceAccount:${google_service_account.redis_sa.email}",
  ]
}

resource "google_kms_key_ring" "key_ring" {
  name     = "redis-key-ring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "crypto_key" {
  name     = "redis-crypto-key"
  key_ring = google_kms_key_ring.key_ring.id
  purpose  = "ENCRYPT_DECRYPT"
}

resource "google_redis_instance_iam_binding" "instance_binding" {
  instance_name = google_redis_instance.instance.name
  role          = "roles/redis.editor"
  members       = [
    "serviceAccount:${google_service_account.redis_sa.email}",
  ]
}