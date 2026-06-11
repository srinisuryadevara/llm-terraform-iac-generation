provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "aws_eks_cluster" "example" {
  name     = var.aws_eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster.id]
    subnet_ids         = [aws_subnet.eks_cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}

resource "aws_iam_role" "eks_cluster" {
  name        = var.aws_eks_cluster_name
  description = "EKS Cluster IAM Role"

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

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_security_group" "eks_cluster" {
  name        = var.aws_eks_cluster_name
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
    Name = var.aws_eks_cluster_name
  }
}

resource "aws_vpc" "eks_cluster" {
  cidr_block = var.aws_vpc_cidr_block

  tags = {
    Name = var.aws_eks_cluster_name
  }
}

resource "aws_subnet" "eks_cluster" {
  cidr_block = var.aws_subnet_cidr_block
  vpc_id     = aws_vpc.eks_cluster.id
  availability_zone = var.aws_availability_zone

  tags = {
    Name = var.aws_eks_cluster_name
  }
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.azure_aks_cluster_name
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  dns_prefix          = var.azure_dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.azure_node_count
    vm_size    = var.azure_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "google_container_cluster" "example" {
  name               = var.gcp_gke_cluster_name
  location           = var.gcp_location
  project            = var.gcp_project
  initial_node_count = var.gcp_node_count

  node_pool {
    name       = "default"
    node_count = var.gcp_node_count
  }
}

variable "aws_region" {
  type = string
}

variable "aws_eks_cluster_name" {
  type = string
}

variable "aws_vpc_cidr_block" {
  type = string
}

variable "aws_subnet_cidr_block" {
  type = string
}

variable "aws_availability_zone" {
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

variable "azure_dns_prefix" {
  type = string
}

variable "azure_node_count" {
  type = number
}

variable "azure_vm_size" {
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

variable "gcp_node_count" {
  type = number
}