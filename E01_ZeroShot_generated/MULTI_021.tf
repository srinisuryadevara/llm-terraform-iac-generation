# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a managed Kubernetes cluster on AWS (EKS)
resource "aws_eks_cluster" "aws_eks" {
  name     = var.aws_eks_cluster_name
  role_arn = aws_iam_role.aws_eks.arn

  vpc_config {
    security_group_ids = [aws_security_group.aws_eks.id]
    subnet_ids         = [aws_subnet.aws_eks.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.aws_eks-AmazonEKSVPCResourceController,
  ]
}

resource "aws_iam_role" "aws_eks" {
  name        = var.aws_eks_cluster_name
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

resource "aws_iam_role_policy_attachment" "aws_eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.aws_eks.name
}

resource "aws_iam_role_policy_attachment" "aws_eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.aws_eks.name
}

resource "aws_security_group" "aws_eks" {
  name        = var.aws_eks_cluster_name
  description = "EKS Cluster Security Group"
  vpc_id      = aws_vpc.aws_eks.id

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
}

resource "aws_vpc" "aws_eks" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "aws_eks" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.aws_eks.id
  availability_zone = "us-west-2a"
}

# Create a managed Kubernetes cluster on Azure (AKS)
resource "azurerm_kubernetes_cluster" "azure_aks" {
  name                = var.azure_aks_cluster_name
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  dns_prefix          = var.azure_aks_dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.azure_aks_node_count
    vm_size    = var.azure_aks_node_size
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create a managed Kubernetes cluster on GCP (GKE)
resource "google_container_cluster" "gcp_gke" {
  name               = var.gcp_gke_cluster_name
  location           = var.gcp_location
  project            = var.gcp_project
  initial_node_count = var.gcp_gke_node_count

  node_pool {
    name       = "default"
    node_count = var.gcp_gke_node_count
  }
}

variable "aws_region" {
  type = string
}

variable "aws_eks_cluster_name" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_aks_cluster_name" {
  type = string
}

variable "azure_aks_dns_prefix" {
  type = string
}

variable "azure_aks_node_count" {
  type = number
}

variable "azure_aks_node_size" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "gcp_gke_cluster_name" {
  type = string
}

variable "gcp_gke_node_count" {
  type = number
}