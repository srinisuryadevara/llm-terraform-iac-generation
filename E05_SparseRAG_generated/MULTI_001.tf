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

variable "azure_subscription_id" {
  type        = string
  default     = "my-azure-subscription-id"
  description = "Azure subscription ID"
}

variable "azure_resource_group_name" {
  type        = string
  default     = "my-azure-resource-group"
  description = "Azure resource group name"
}

variable "cluster_name" {
  type        = string
  default     = "my-kubernetes-cluster"
  description = "Kubernetes cluster name"
}

variable "cluster_version" {
  type        = string
  default     = "1.22"
  description = "Kubernetes cluster version"
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

# Create EKS cluster
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

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

# Create AKS cluster
module "aks" {
  source = "../../aks"

  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  cluster_name        = var.cluster_name
  kubernetes_version  = var.cluster_version

  network_profile = {
    network_plugin = "azure"
  }

  default_node_pool = {
    name       = "default"
    node_count = 3
    vm_size     = "Standard_DS2_v2"
  }
}

# Create GKE cluster
module "gke" {
  source = "../../gke"

  project_id = var.gcp_project
  location   = var.gcp_region
  cluster_id = var.cluster_name

  node_pool = {
    name       = "default"
    node_count = 3
    machine_type = "n1-standard-1"
  }
}

# Create VPC
module "vpc" {
  source = "../.."

  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Create KMS key for EKS
resource "aws_kms_key" "eks" {
  description             = "EKS KMS key"
  deletion_window_in_days = 10
}

# Create Azure resource group
resource "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

# Create GCP project
resource "google_project" "example" {
  project_id = var.gcp_project
}