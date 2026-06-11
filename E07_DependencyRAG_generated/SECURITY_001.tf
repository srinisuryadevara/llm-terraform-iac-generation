provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "credentials_file" {
  type = string
}

variable "gke_num_nodes" {
  type = map(number)
}

variable "gke_node_machine_type" {
  type = string
}

variable "gke_master_user" {
  type = string
}

variable "gke_master_pass" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

data "google_client_config" "default" {
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.27."
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_container_cluster" "primary" {
  provider = google-beta
  name               = "ca-gke-${terraform.workspace}-cluster"
  location          = var.region
  initial_node_count = var.gke_num_nodes[terraform.workspace]

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.0.0.0/28"
  }

  master_auth {
    username = var.gke_master_user
    password = var.gke_master_pass
  }

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    disk_size_gb = 10
    machine_type = var.gke_node_machine_type
    tags         = ["gke-node"]
  }

  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.subnet,
  ]
}

resource "google_container_node_pool" "primary" {
  name       = google_container_cluster.primary.name
  location   = var.region
  cluster    = google_container_cluster.primary.name
  version = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    disk_size_gb = 10
    machine_type = var.gke_node_machine_type
    tags         = ["gke-node"]
  }
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags = ["gke-node"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["gke-node"]
}