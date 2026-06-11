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

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "redis_instance_name" {
  type        = string
  description = "The name of the Redis instance"
}

variable "redis_instance_tier" {
  type        = string
  description = "The tier of the Redis instance"
}

variable "redis_instance_memory_size_gb" {
  type        = number
  description = "The memory size of the Redis instance in GB"
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["private-vpc"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["private-subnet"]
}

resource "google_redis_instance" "instance" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = var.redis_instance_memory_size_gb
  region         = var.region
  labels         = {
    environment = "private"
  }
  authorized_network = google_compute_network.vpc.id
  transit_encryption_mode = "SERVER_AUTHENTICATION"
}

resource "google_compute_firewall" "allow_redis" {
  name    = "allow-redis"
  network = google_compute_network.vpc.id
  allow {
    protocol = "TCP"
    ports    = ["6379"]
  }
  target_tags = ["private-vpc"]
  source_tags = ["private-subnet"]
  depends_on  = [google_compute_network.vpc]
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

resource "google_kms_key_ring_iam_binding" "key_ring_iam_binding" {
  key_ring_id = google_kms_key_ring.key_ring.id
  role        = "roles/owner"
  members     = ["serviceAccount:service-${var.project_id}@gcp-sa-redis.iam.gserviceaccount.com"]
}