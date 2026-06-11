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
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    subnet_ids = [aws_subnet.aws_subnet.id]
  }
  tags = {
    Name        = "aws-eks-cluster"
    Environment = "managed-k8s"
  }
}

# Create an IAM role for the EKS cluster on AWS
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
      },
    ]
  })
  tags = {
    Name        = "aws-eks-role"
    Environment = "managed-k8s"
  }
}

# Create a resource group on Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = var.azure_rg_name
  location = var.azure_location
  tags = {
    Name        = "azure-rg"
    Environment = "managed-k8s"
  }
}

# Create an AKS cluster on Azure
resource "azurerm_kubernetes_cluster" "azure_aks_cluster" {
  name                = var.aks_cluster_name
  resource_group_name = azurerm_resource_group.azure_rg.name
  location            = azurerm_resource_group.azure_rg.location
  sku_tier            = "Free"
  kubernetes_version = "1.23.8"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
  tags = {
    Name        = "azure-aks-cluster"
    Environment = "managed-k8s"
  }
}

# Create a GKE cluster on GCP
resource "google_container_cluster" "gke_cluster" {
  name               = var.gke_cluster_name
  location           = var.gcp_region
  project            = var.gcp_project
  initial_node_count = 1

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
  labels = {
    Name        = "gke-cluster"
    Environment = "managed-k8s"
  }
}

variable "aws_region" {
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

variable "eks_cluster_name" {
  type        = string
  sensitive   = true
}

variable "azure_rg_name" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "aks_cluster_name" {
  type        = string
  sensitive   = true
}

variable "gke_cluster_name" {
  type        = string
  sensitive   = true
}

output "aws_vpc_id" {
  value       = aws_vpc.aws_vpc.id
  description = "AWS VPC ID"
}

output "aws_eks_cluster_id" {
  value       = aws_eks_cluster.aws_eks_cluster.id
  description = "AWS EKS Cluster ID"
}

output "aws_eks_cluster_endpoint" {
  value       = aws_eks_cluster.aws_eks_cluster.endpoint
  description = "AWS EKS Cluster Endpoint"
}

output "azure_rg_name" {
  value       = azurerm_resource_group.azure_rg.name
  description = "Azure Resource Group Name"
}

output "azure_aks_cluster_id" {
  value       = azurerm_kubernetes_cluster.azure_aks_cluster.id
  description = "Azure AKS Cluster ID"
}

output "gcp_gke_cluster_id" {
  value       = google_container_cluster.gke_cluster.id
  description = "GCP GKE Cluster ID"
}

output "gcp_gke_cluster_endpoint" {
  value       = google_container_cluster.gke_cluster.endpoint
  description = "GCP GKE Cluster Endpoint"
}