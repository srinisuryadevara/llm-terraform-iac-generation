# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a VPC for EKS
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet for EKS
resource "aws_subnet" "eks_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.eks_vpc.id
  availability_zone = "us-west-2a"
}

# Create an EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    subnet_ids = [aws_subnet.eks_subnet.id]
  }
}

# Create an IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name        = var.eks_cluster_name
  description = "EKS Cluster Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Create a resource group for AKS
resource "azurerm_resource_group" "aks_rg" {
  name     = var.aks_resource_group_name
  location = var.azure_location
}

# Create an AKS cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create a network for GKE
resource "google_compute_network" "gke_network" {
  name                    = var.gke_network_name
  auto_create_subnetworks = false
}

# Create a subnet for GKE
resource "google_compute_subnetwork" "gke_subnet" {
  name          = var.gke_subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.gke_network.id
}

# Create a GKE cluster
resource "google_container_cluster" "gke_cluster" {
  name               = var.gke_cluster_name
  location           = var.gcp_region
  project            = var.gcp_project
  network            = google_compute_network.gke_network.id
  subnetwork         = google_compute_subnetwork.gke_subnet.id

  # We can't create a cluster with no node pool defined, but we want to create the
  # node pool separately, so we create the cluster with a minimal node pool and
  # then remove the node pool.
  remove_default_node_pool = true
  initial_node_count       = 1
}

# Create a node pool for GKE
resource "google_container_node_pool" "gke_node_pool" {
  name       = var.gke_node_pool_name
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
}

variable "eks_cluster_name" {
  type        = string
  default     = "my-eks-cluster"
}

variable "gcp_project" {
  type        = string
  default     = "my-gcp-project"
}

variable "gcp_region" {
  type        = string
  default     = "us-central1"
}

variable "gcp_credentials" {
  type        = string
  sensitive   = true
}

variable "aks_resource_group_name" {
  type        = string
  default     = "my-aks-resource-group"
}

variable "aks_cluster_name" {
  type        = string
  default     = "my-aks-cluster"
}

variable "aks_dns_prefix" {
  type        = string
  default     = "my-aks-dns-prefix"
}

variable "azure_location" {
  type        = string
  default     = "West US"
}

variable "azure_subscription_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  type        = string
  sensitive   = true
}

variable "gke_network_name" {
  type        = string
  default     = "my-gke-network"
}

variable "gke_subnet_name" {
  type        = string
  default     = "my-gke-subnet"
}

variable "gke_cluster_name" {
  type        = string
  default     = "my-gke-cluster"
}

variable "gke_node_pool_name" {
  type        = string
  default     = "my-gke-node-pool"
}