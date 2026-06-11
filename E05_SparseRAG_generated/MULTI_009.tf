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

# Configure the Kubernetes Provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
    }
  }
}

# Define input variables
variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"
}

variable "gcp_project" {
  type        = string
  default     = "my-gcp-project"
  description = "GCP project ID"
}

variable "gcp_region" {
  type        = string
  default     = "us-central1"
  description = "GCP region"
}

variable "aks_resource_group_name" {
  type        = string
  default     = "my-aks-rg"
  description = "AKS resource group name"
}

variable "aks_location" {
  type        = string
  default     = "West US"
  description = "AKS location"
}

# Define locals
locals {
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.22"
  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

# Create EKS cluster
module "eks" {
  source = "../.."

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

# Create AKS cluster
module "aks" {
  source = "../../modules/aks"

  resource_group_name = var.aks_resource_group_name
  location            = var.aks_location
  cluster_name        = local.name
  kubernetes_version  = local.cluster_version

  node_pool_name       = "default"
  node_count           = 3
  vm_size              = "Standard_DS2_v2"
  os_disk_size_gb      = 30
  max_pods             = 110
  enable_auto_scaling  = true
  min_count            = 1
  max_count            = 3
}

# Create GKE cluster
module "gke" {
  source = "../../modules/gke"

  project_id = var.gcp_project
  region     = var.gcp_region
  cluster_name = local.name
  node_pool_name = "default"
  node_count     = 3
  machine_type   = "n1-standard-1"
  disk_size_gb   = 30
  preemptible    = false
  autoscaling    = true
  min_node_count = 1
  max_node_count = 3
}

# Create VPC for EKS
module "vpc" {
  source = "../../modules/vpc"

  cidr_block = "10.0.0.0/16"
}

# Create KMS key for EKS
resource "aws_kms_key" "eks" {
  description             = "EKS KMS key"
  deletion_window_in_days = 10
}

# Create service account for EKS
resource "aws_iam_role" "eks" {
  name        = "eks-service-account"
  description = "EKS service account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}