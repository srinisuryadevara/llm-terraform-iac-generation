# ---------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 0.12 syntax and features that are available only since version 0.12.7.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12.7"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  version = "~> 3.52.0"
  project = var.project
  region  = var.region
}

provider "google-beta" {
  version = "~> 3.52.0"
  project = var.project
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE GKE CLUSTER
# We want to make a cluster with a node pool, and manage them all with the fine-grained google_container_node_pool resource
# ---------------------------------------------------------------------------------------------------------------------
resource "google_container_cluster" "cluster" {
  provider = google-beta

  name        = var.name
  description = var.description

  project    = var.project
  location   = var.location
  network    = var.network
  subnetwork = var.subnetwork

  # Enable network policy
  network_policy {
    enabled = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE GKE NODE POOL
# We want to make a node pool with a specific machine type and disk size
# ---------------------------------------------------------------------------------------------------------------------
resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.name
  location   = var.location
  project    = var.project
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE NETWORK POLICY
# We want to create a network policy that allows ingress traffic from the node pool
# ---------------------------------------------------------------------------------------------------------------------
resource "google_container_network_policy" "network_policy" {
  provider = google-beta

  name        = var.network_policy_name
  project     = var.project
  location    = var.location
  cluster     = google_container_cluster.cluster.name

  policy {
    ingress {
      from {
        pod_selector {
          match_labels = {
            app = var.app_label
          }
        }
      }
      to {
        pod_selector {
          match_labels = {
            app = var.app_label
          }
        }
      }
      allow {
        protocol = "TCP"
        ports    = var.allowed_ports
      }
    }
  }
}