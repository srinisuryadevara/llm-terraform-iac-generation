variable "project" {
  type = string
}

variable "region" {
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
  sensitive = true
}

variable "gke_master_pass" {
  type = string
  sensitive = true
}

provider "google" {
  credentials = file("~/.config/gcloud/credentials.json")
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  credentials = file("~/.config/gcloud/credentials.json")
  project     = var.project
  region      = var.region
}

data "google_client_config" "default" {
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.27."
}

resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_compute_firewall" "gke_firewall" {
  name    = "gke-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_container_cluster" "primary" {
  provider = google-beta
  name               = "gke-cluster"
  location           = var.region
  initial_node_count = var.gke_num_nodes["default"]

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
    workload_pool = "projects/${var.project}/locations/global/workloadIdentityPools/default"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "10.0.0.0/16"
      display_name = "gke-vpc"
    }
  }
}

resource "google_container_node_pool" "primary" {
  name       = "gke-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.gke_num_nodes["default"]

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