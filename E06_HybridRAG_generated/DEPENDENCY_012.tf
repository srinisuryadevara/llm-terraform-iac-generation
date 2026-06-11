resource "google_container_node_pool" "gke_node_pool" {
  name       = "gke-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes[terraform.workspace]

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

resource "google_container_cluster" "primary" {
  name               = "ca-gke-${terraform.workspace}-cluster"
  zone               = "${var.region}-a"
  initial_node_count = 0

  additional_zones = [
    "${var.region}-b",
  ]

  master_auth {
    username = "${var.gke_master_user}"
    password = "${var.gke_master_pass}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    disk_size_gb = 10
    machine_type = "${var.gke_node_machine_type}"
    tags         = ["gke-node"]
  }
}