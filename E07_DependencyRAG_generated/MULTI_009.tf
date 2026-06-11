# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create AWS EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks.id]
    subnet_ids         = aws_subnet.eks.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}

# Create AWS EKS Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.eks.*.id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node-AmazonEKS_CNI_Policy,
  ]
}

# Create Azure AKS Cluster
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_cluster_name
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    name       = var.aks_node_pool_name
    node_count = 1
    vm_size    = var.aks_node_size
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create Google GKE Cluster
resource "google_container_cluster" "this" {
  name               = var.gke_cluster_name
  location           = var.gcp_location
  project            = var.gcp_project
  initial_node_count = 1

  node_pool {
    name       = var.gke_node_pool_name
    node_count = 1
  }
}

# Create Azure Resource Group
resource "azurerm_resource_group" "this" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

# Create AWS IAM Role for EKS
resource "aws_iam_role" "eks" {
  name        = var.eks_iam_role_name
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

# Create AWS IAM Role for EKS Node
resource "aws_iam_role" "eks_node" {
  name        = var.eks_node_iam_role_name
  description = "EKS Node IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Create AWS IAM Role Policy Attachments
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

# Create AWS Security Group for EKS
resource "aws_security_group" "eks" {
  name        = var.eks_security_group_name
  description = "EKS Security Group"
  vpc_id      = aws_vpc.eks.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create AWS VPC for EKS
resource "aws_vpc" "eks" {
  cidr_block = var.eks_vpc_cidr

  tags = {
    Name = var.eks_vpc_name
  }
}

# Create AWS Subnet for EKS
resource "aws_subnet" "eks" {
  count = 2

  vpc_id            = aws_vpc.eks.id
  cidr_block        = cidrsubnet(aws_vpc.eks.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.eks_vpc_name}-subnet-${count.index}"
  }
}

# Get AWS Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "eks_node_group_name" {
  type        = string
  description = "EKS Node Group Name"
}

variable "aks_cluster_name" {
  type        = string
  description = "AKS Cluster Name"
}

variable "aks_dns_prefix" {
  type        = string
  description = "AKS DNS Prefix"
}

variable "aks_node_pool_name" {
  type        = string
  description = "AKS Node Pool Name"
}

variable "aks_node_size" {
  type        = string
  description = "AKS Node Size"
}

variable "gke_cluster_name" {
  type        = string
  description = "GKE Cluster Name"
}

variable "gke_node_pool_name" {
  type        = string
  description = "GKE Node Pool Name"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "eks_iam_role_name" {
  type        = string
  description = "EKS IAM Role Name"
}

variable "eks_node_iam_role_name" {
  type        = string
  description = "EKS Node IAM Role Name"
}

variable "eks_security_group_name" {
  type        = string
  description = "EKS Security Group Name"
}

variable "eks_vpc_name" {
  type        = string
  description = "EKS VPC Name"
}

variable "eks_vpc_cidr" {
  type        = string
  description = "EKS VPC CIDR"
}