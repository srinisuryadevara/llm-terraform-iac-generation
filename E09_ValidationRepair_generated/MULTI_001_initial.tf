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

# Create a managed Kubernetes cluster on AWS (EKS)
resource "aws_eks_cluster" "example" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster.id]
    subnet_ids         = [aws_subnet.eks_cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

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
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_security_group" "eks_cluster" {
  name        = var.eks_cluster_name
  description = "EKS Cluster Security Group"
  vpc_id      = aws_vpc.eks_cluster.id

  ingress {
    description = "Allow inbound traffic from the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_vpc" "eks_cluster" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "eks_cluster" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.eks_cluster.id
  availability_zone = var.aws_availability_zone
}

# Create a managed Kubernetes cluster on Azure (AKS)
resource "azurerm_kubernetes_cluster" "example" {
  name                = var.aks_cluster_name
  location            = var.azure_location
  resource_group_name = var.azure_resource_group
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create a managed Kubernetes cluster on GCP (GKE)
resource "google_container_cluster" "example" {
  name               = var.gke_cluster_name
  location           = var.gcp_location
  project            = var.gcp_project
  initial_node_count = var.gke_node_count

  node_pool {
    name       = "default"
    node_count = var.gke_node_count
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS Availability Zone"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "aks_cluster_name" {
  type        = string
  description = "AKS Cluster Name"
}

variable "aks_dns_prefix" {
  type        = string
  description = "AKS DNS Prefix"
}

variable "aks_node_count" {
  type        = number
  description = "AKS Node Count"
}

variable "aks_vm_size" {
  type        = string
  description = "AKS VM Size"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_location" {
  type        = string
  description = "GCP Location"
}

variable "gke_cluster_name" {
  type        = string
  description = "GKE Cluster Name"
}

variable "gke_node_count" {
  type        = number
  description = "GKE Node Count"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "azure_resource_group" {
  type        = string
  description = "Azure Resource Group"
}