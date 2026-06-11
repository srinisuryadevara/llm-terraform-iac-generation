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

# Create a VPC on AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "aws-vpc"
    Environment = "managed-k8s"
  }
}

# Create a subnet on AWS
resource "aws_subnet" "aws_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = "us-west-2a"
  tags = {
    Name        = "aws-subnet"
    Environment = "managed-k8s"
  }
}

# Create an EKS cluster on AWS
resource "aws_eks_cluster" "aws_eks_cluster" {
  name     = var.aws_eks_cluster_name
  role_arn = aws_iam_role.aws_eks_cluster_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.aws_subnet.id]
  }
  tags = {
    Name        = "aws-eks-cluster"
    Environment = "managed-k8s"
  }
}

# Create an IAM role for the EKS cluster on AWS
resource "aws_iam_role" "aws_eks_cluster_role" {
  name        = var.aws_eks_cluster_role_name
  description = "EKS Cluster Role"
  tags = {
    Name        = "aws-eks-cluster-role"
    Environment = "managed-k8s"
  }
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

# Create a resource group on Azure
resource "azurerm_resource_group" "azure_resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
  tags = {
    Name        = "azure-resource-group"
    Environment = "managed-k8s"
  }
}

# Create an AKS cluster on Azure
resource "azurerm_kubernetes_cluster" "azure_aks_cluster" {
  name                = var.azure_aks_cluster_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  dns_prefix          = var.azure_aks_dns_prefix
  tags = {
    Name        = "azure-aks-cluster"
    Environment = "managed-k8s"
  }
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
}

# Create a GKE cluster on GCP
resource "google_container_cluster" "gcp_gke_cluster" {
  name               = var.gcp_gke_cluster_name
  location           = var.gcp_location
  project            = var.gcp_project
  initial_node_count = 1
  labels = {
    Name        = "gcp-gke-cluster"
    Environment = "managed-k8s"
  }
}

# Create a node pool for the GKE cluster on GCP
resource "google_container_node_pool" "gcp_gke_node_pool" {
  name       = var.gcp_gke_node_pool_name
  cluster    = google_container_cluster.gcp_gke_cluster.name
  node_count = 1
  labels = {
    Name        = "gcp-gke-node-pool"
    Environment = "managed-k8s"
  }
  node_config {
    preemptible  = true
    machine_type = "e2-medium"
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
  sensitive   = true
}

variable "aws_eks_cluster_name" {
  type        = string
  sensitive   = true
}

variable "aws_eks_cluster_role_name" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "azure_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_aks_cluster_name" {
  type        = string
  sensitive   = true
}

variable "azure_aks_dns_prefix" {
  type        = string
  sensitive   = true
}

variable "gcp_project" {
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  type        = string
  sensitive   = true
}

variable "gcp_location" {
  type        = string
  sensitive   = true
}

variable "gcp_gke_cluster_name" {
  type        = string
  sensitive   = true
}

variable "gcp_gke_node_pool_name" {
  type        = string
  sensitive   = true
}

output "aws_vpc_id" {
  value       = aws_vpc.aws_vpc.id
  description = "The ID of the AWS VPC"
}

output "aws_eks_cluster_id" {
  value       = aws_eks_cluster.aws_eks_cluster.id
  description = "The ID of the AWS EKS cluster"
}

output "aws_eks_cluster_endpoint" {
  value       = aws_eks_cluster.aws_eks_cluster.endpoint
  description = "The endpoint of the AWS EKS cluster"
}

output "azure_resource_group_name" {
  value       = azurerm_resource_group.azure_resource_group.name
  description = "The name of the Azure resource group"
}

output "azure_aks_cluster_id" {
  value       = azurerm_kubernetes_cluster.azure_aks_cluster.id
  description = "The ID of the Azure AKS cluster"
}

output "gcp_gke_cluster_id" {
  value       = google_container_cluster.gcp_gke_cluster.id
  description = "The ID of the GCP GKE cluster"
}

output "gcp_gke_cluster_endpoint" {
  value       = google_container_cluster.gcp_gke_cluster.endpoint
  description = "The endpoint of the GCP GKE cluster"
}