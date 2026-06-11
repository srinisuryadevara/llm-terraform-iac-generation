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
  credentials = file(var.google_credentials_file)
  project     = var.google_project
  region      = var.google_region
}

# Configure the Google Cloud Beta Provider
provider "google-beta" {
  credentials = file(var.google_credentials_file)
  project     = var.google_project
  region      = var.google_region
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

# Configure the Azure Kubernetes Provider
provider "kubernetes" {
  alias                  = "aks"
  host                   = module.aks.kube_config
  cluster_ca_certificate = base64decode(module.aks.kube_config_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "az"
    args = [
      "account",
      "get-access-token",
      "--resource",
      "https://management.azure.com/",
    ]
  }
}

# Configure the Google Kubernetes Provider
provider "kubernetes" {
  alias                  = "gke"
  host                   = module.gke.cluster_endpoint
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gcloud"
    args = [
      "container",
      "clusters",
      "get-credentials",
      module.gke.cluster_name,
      "--region",
      var.google_region,
    ]
  }
}

# Define locals
locals {
  aws_cluster_name       = "aws-eks-cluster"
  azure_cluster_name     = "azure-aks-cluster"
  google_cluster_name    = "google-gke-cluster"
  aws_region             = var.aws_region
  azure_location         = var.azure_location
  google_region          = var.google_region
  cluster_version        = "1.22"
  tags = {
    Environment = "dev"
  }
}

# Create AWS EKS Cluster
module "eks" {
  source = "../aws-eks"

  cluster_name                    = local.aws_cluster_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.aws_vpc.id
  subnet_ids = module.aws_vpc.private_subnets
}

# Create Azure AKS Cluster
module "aks" {
  source = "../azure-aks"

  cluster_name                    = local.azure_cluster_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  resource_group_name = module.azure_rg.name
  location            = local.azure_location
  vnet_id             = module.azure_vnet.id
  subnet_id           = module.azure_vnet.subnets[0].id
}

# Create Google GKE Cluster
module "gke" {
  source = "../google-gke"

  cluster_name                    = local.google_cluster_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  project_id = var.google_project_id
  location   = local.google_region
  network    = module.google_vpc.id
  subnetwork = module.google_vpc.subnets[0].id
}

# Create AWS VPC
module "aws_vpc" {
  source = "../aws-vpc"

  name = "aws-vpc"
  cidr = "10.0.0.0/16"
}

# Create Azure Resource Group
module "azure_rg" {
  source = "../azure-rg"

  name     = "azure-rg"
  location = local.azure_location
}

# Create Azure Virtual Network
module "azure_vnet" {
  source = "../azure-vnet"

  name                = "azure-vnet"
  resource_group_name = module.azure_rg.name
  location            = local.azure_location
  address_space       = ["10.0.0.0/16"]
}

# Create Google Virtual Network
module "google_vpc" {
  source = "../google-vpc"

  name                    = "google-vpc"
  project_id              = var.google_project_id
  auto_create_subnetworks = false
}

# Create Google Subnetwork
module "google_subnetwork" {
  source = "../google-subnetwork"

  name          = "google-subnetwork"
  project_id    = var.google_project_id
  network       = module.google_vpc.id
  ip_cidr_range = "10.0.0.0/24"
  region        = local.google_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "google_credentials_file" {
  type        = string
  description = "Google Credentials File"
}

variable "google_project" {
  type        = string
  description = "Google Project"
}

variable "google_region" {
  type        = string
  description = "Google Region"
}

variable "google_project_id" {
  type        = string
  description = "Google Project ID"
}