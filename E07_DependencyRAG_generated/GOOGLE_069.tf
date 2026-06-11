provider "google" {
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  project     = var.project
  region      = var.region
}

variable "project" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  type        = string
  default     = "memorystore-vpc"
}

variable "subnet_name" {
  type        = string
  default     = "memorystore-subnet"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.0.0/24"
}

variable "redis_instance_name" {
  type        = string
  default     = "memorystore-redis"
}

variable "redis_tier" {
  type        = string
  default     = "BASIC"
}

variable "redis_memory_size_gb" {
  type        = number
  default     = 1
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_redis" {
  name    = "allow-redis"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
}

resource "google_redis_instance" "redis" {
  name                    = var.redis_instance_name
  tier                    = var.redis_tier
  memory_size_gb          = var.redis_memory_size_gb
  project                 = var.project
  location_id             = "${var.region}-c"
  authorized_network      = google_compute_network.vpc.id
  redis_version           = "REDIS_6_X"
}

resource "google_compute_instance" "redis_client" {
  name         = "redis-client"
  machine_type = "f1-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  tags = ["redis"]
}