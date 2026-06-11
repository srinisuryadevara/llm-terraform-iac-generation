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

# Configure the Kubernetes Provider for AWS
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

# Configure the Kubernetes Provider for Azure
provider "kubernetes" {
  alias                  = "aks"
  host                   = module.aks.kube_config[0].host
  cluster_ca_certificate = base64decode(module.aks.kube_config[0].cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "az"
    args = [
      "account",
      "get-access-token",
      "--resource",
      "https://management.azure.com/",
    ]
  }
}

# Configure the Kubernetes Provider for Google Cloud
provider "kubernetes" {
  alias                  = "gke"
  host                   = module.gke.endpoint
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "gcloud"
    args = [
      "container",
      "clusters",
      "get-credentials",
      module.gke.name,
      "--region",
      var.google_region,
    ]
  }
}

# Define the AWS EKS Module
module "eks" {
  source = "./eks"

  cluster_name                    = var.eks_cluster_name
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_private_access = var.eks_cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.eks_cluster_endpoint_public_access

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

# Define the Azure AKS Module
module "aks" {
  source = "./aks"

  resource_group_name = var.aks_resource_group_name
  cluster_name        = var.aks_cluster_name
  location            = var.aks_location
  kubernetes_version  = var.aks_kubernetes_version
}

# Define the Google Cloud GKE Module
module "gke" {
  source = "./gke"

  project_id = var.google_project
  zone       = var.google_zone
  cluster_id = var.gke_cluster_name
}

# Define the VPC Module for AWS
module "vpc" {
  source = "./vpc"

  cidr_block = var.vpc_cidr_block
}

# Define the variables
variable "aws_region" {
  type        = string
  description = "The AWS region"
}

variable "azure_subscription_id" {
  type        = string
  description = "The Azure subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "The Azure client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "The Azure client secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "The Azure tenant ID"
}

variable "google_credentials_file" {
  type        = string
  description = "The path to the Google Cloud credentials file"
}

variable "google_project" {
  type        = string
  description = "The Google Cloud project ID"
}

variable "google_region" {
  type        = string
  description = "The Google Cloud region"
}

variable "google_zone" {
  type        = string
  description = "The Google Cloud zone"
}

variable "eks_cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "eks_cluster_version" {
  type        = string
  description = "The version of the EKS cluster"
}

variable "eks_cluster_endpoint_private_access" {
  type        = bool
  description = "Whether to enable private access to the EKS cluster endpoint"
}

variable "eks_cluster_endpoint_public_access" {
  type        = bool
  description = "Whether to enable public access to the EKS cluster endpoint"
}

variable "aks_resource_group_name" {
  type        = string
  description = "The name of the resource group for the AKS cluster"
}

variable "aks_cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "aks_location" {
  type        = string
  description = "The location of the AKS cluster"
}

variable "aks_kubernetes_version" {
  type        = string
  description = "The version of Kubernetes for the AKS cluster"
}

variable "gke_cluster_name" {
  type        = string
  description = "The name of the GKE cluster"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}