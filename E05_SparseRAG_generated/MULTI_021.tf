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
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_id,
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_id,
      ]
    }
  }
}

# Define input variables
variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS Region"
}

variable "gcp_project" {
  type        = string
  default     = "your-gcp-project"
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  default     = "us-central1"
  description = "GCP Region"
}

variable "azure_subscription_id" {
  type        = string
  default     = "your-azure-subscription-id"
  description = "Azure Subscription ID"
}

variable "azure_resource_group_name" {
  type        = string
  default     = "your-azure-resource-group"
  description = "Azure Resource Group Name"
}

variable "cluster_name" {
  type        = string
  default     = "your-cluster-name"
  description = "Cluster Name"
}

variable "cluster_version" {
  type        = string
  default     = "1.22"
  description = "Cluster Version"
}

# Define locals
locals {
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

# Create EKS Cluster
module "eks" {
  source = "../.."

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    },
  ]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

# Create AKS Cluster
module "aks" {
  source = "../../aks"

  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  cluster_name        = var.cluster_name
  kubernetes_version  = var.cluster_version

  network_profile = {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  default_node_pool = {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_DS2_v2"
  }
}

# Create GKE Cluster
module "gke" {
  source = "../../gke"

  project_id = var.gcp_project
  location   = var.gcp_region
  cluster_name = var.cluster_name

  node_pools = [
    {
      name       = "default-pool"
      node_count = 3
      machine_type = "e2-medium"
    },
  ]
}

# Create VPC
module "vpc" {
  source = "../../vpc"

  cidr = "10.0.0.0/16"
}

# Create KMS Key for EKS
resource "aws_kms_key" "eks" {
  description             = "EKS KMS Key"
  deletion_window_in_days = 10
}

# Create Azure Resource Group
resource "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

# Create GCP Network
resource "google_compute_network" "example" {
  name                    = "example-network"
  auto_create_subnetworks = false
}

# Create GCP Subnetwork
resource "google_compute_subnetwork" "example" {
  name          = "example-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.example.id
}