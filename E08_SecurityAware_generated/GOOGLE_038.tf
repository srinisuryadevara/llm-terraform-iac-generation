provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
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

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR block"
}

variable "redis_instance_name" {
  type        = string
  description = "Memorystore Redis instance name"
}

variable "redis_instance_tier" {
  type        = string
  description = "Memorystore Redis instance tier"
}

resource "google_compute_network" "vpc_network" {
  name                    = "private-vpc-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1460
  description             = "Private VPC network for Memorystore Redis instance"
  tags                    = ["private-vpc", "memorystore-redis"]
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "private-vpc-subnetwork"
  ip_cidr_range = var.vpc_cidr
  network       = google_compute_network.vpc_network.id
  region        = var.region
  description   = "Private VPC subnetwork for Memorystore Redis instance"
  tags          = ["private-vpc", "memorystore-redis"]
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-firewall-rule"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  description   = "Allow SSH traffic from specific CIDR block"
  tags          = ["ssh-firewall", "memorystore-redis"]
}

resource "google_redis_instance" "redis_instance" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = 1
  region         = var.region
  authorized_networks {
    name = google_compute_network.vpc_network.id
  }
  labels = {
    "environment" = "private-vpc"
    "application" = "memorystore-redis"
  }
  transit_encryption = "SERVER_AUTHENTICATION"
  maintenance_policy {
    weekly_maintenance_window {
      day  = "SATURDAY"
      start_time = "02:00"
    }
  }
  depends_on = [google_compute_network.vpc_network]
}

resource "google_service_account" "redis_service_account" {
  name        = "memorystore-redis-service-account"
  description = "Service account for Memorystore Redis instance"
}

resource "google_service_account_key" "redis_service_account_key" {
  service_account_id = google_service_account.redis_service_account.id
}

resource "google_iam_policy" "redis_iam_policy" {
  name        = "memorystore-redis-iam-policy"
  description = "IAM policy for Memorystore Redis instance"

  policy_data = jsonencode({
    "version" : "2012-10-17",
    "statement" = [
      {
        "effect" : "Allow",
        "action" : [
          "redis.instances.get",
          "redis.instances.list",
          "redis.instances.update",
        ],
        "resource" : "*"
      },
    ]
  })
}

resource "google_iam_role" "redis_iam_role" {
  name        = "memorystore-redis-iam-role"
  description = "IAM role for Memorystore Redis instance"

  permissions = [
    "redis.instances.get",
    "redis.instances.list",
    "redis.instances.update",
  ]
}

resource "google_iam_role_policy_attachment" "redis_iam_role_policy_attachment" {
  role       = google_iam_role.redis_iam_role.name
  policy_arn = google_iam_policy.redis_iam_policy.arn
}