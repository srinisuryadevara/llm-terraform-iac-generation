provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "redis_instance_name" {
  type        = string
  description = "Memorystore Redis instance name"
}

variable "redis_instance_tier" {
  type        = string
  description = "Memorystore Redis instance tier"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR block"
}

resource "google_compute_network" "vpc" {
  name                    = "private-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
  project                 = var.project_id
  description             = "Private VPC for Memorystore Redis instance"
  tags                    = ["private-vpc", "memorystore-redis"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "private-subnet"
  ip_cidr_range = var.vpc_cidr
  network       = google_compute_network.vpc.id
  project       = var.project_id
  region        = var.region
  description   = "Private subnet for Memorystore Redis instance"
  tags          = ["private-subnet", "memorystore-redis"]
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  description   = "Allow SSH from specific CIDR block"
  tags          = ["allow-ssh", "memorystore-redis"]
}

resource "google_redis_instance" "instance" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = 1
  project        = var.project_id
  region         = var.region
  authorized_network = google_compute_network.vpc.id
  description    = "Memorystore Redis instance"
  tags           = ["memorystore-redis", "private-vpc"]
}

resource "google_kms_key_ring" "key_ring" {
  name     = "memorystore-redis-key-ring"
  location = var.region
  project  = var.project_id
  description = "KMS key ring for Memorystore Redis instance"
  tags      = ["memorystore-redis", "kms-key-ring"]
}

resource "google_kms_crypto_key" "crypto_key" {
  name     = "memorystore-redis-crypto-key"
  key_ring = google_kms_key_ring.key_ring.id
  project  = var.project_id
  location = var.region
  description = "KMS crypto key for Memorystore Redis instance"
  tags      = ["memorystore-redis", "kms-crypto-key"]
}

resource "google_redis_instance" "instance_with_kms" {
  name           = "${var.redis_instance_name}-with-kms"
  tier           = var.redis_instance_tier
  memory_size_gb = 1
  project        = var.project_id
  region         = var.region
  authorized_network = google_compute_network.vpc.id
  kms_key_name    = google_kms_crypto_key.crypto_key.id
  description    = "Memorystore Redis instance with KMS encryption"
  tags           = ["memorystore-redis", "private-vpc", "kms-encryption"]
}