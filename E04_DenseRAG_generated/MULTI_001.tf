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
  host                   = module.aks.kube_config[0].host
  cluster_ca_certificate = base64decode(module.aks.kube_config[0].cluster_ca_certificate)

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
  host                   = module.gke.endpoint
  cluster_ca_certificate = base64decode(module.gke.master_auth[0].cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
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

# Define locals
locals {
  aws_name            = "aws-eks-${var.environment}"
  azure_name          = "azure-aks-${var.environment}"
  google_name         = "google-gke-${var.environment}"
  cluster_version     = "1.22"
  aws_region          = var.aws_region
  azure_region        = var.azure_region
  google_region       = var.google_region

  tags = {
    Environment = var.environment
  }
}

# Define data sources
data "aws_caller_identity" "current" {}
data "azurerm_subscription" "current" {}
data "google_client_config" "client" {}

# Define AWS EKS module
module "eks" {
  source = "../aws-eks"

  cluster_name                    = local.aws_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.aws_vpc.vpc_id
  subnet_ids = module.aws_vpc.private_subnets
}

# Define Azure AKS module
module "aks" {
  source = "../azure-aks"

  resource_group_name = module.azure_rg.name
  location            = var.azure_region
  cluster_name        = local.azure_name
  kubernetes_version  = local.cluster_version

  vnet_subnet_id = module.azure_vnet.subnet_id
}

# Define Google GKE module
module "gke" {
  source = "../google-gke"

  project_id = var.google_project
  name       = local.google_name
  location   = var.google_region
  network    = module.google_vpc.self_link
  subnetwork = module.google_vpc.subnet.self_link

  node_pools = [
    {
      name               = "default-node-pool"
      node_count         = 1
      vm_size            = "n1-standard-1"
      disk_size_gb       = 50
      preemptible        = false
      max_pods_per_node  = 110
      local_ssd_count    = 0
      oauth_scopes       = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring"]
    },
  ]
}

# Define AWS VPC module
module "aws_vpc" {
  source = "../aws-vpc"

  name = "aws-vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# Define Azure resource group module
module "azure_rg" {
  source = "../azure-rg"

  name     = "azure-rg-${var.environment}"
  location = var.azure_region
}

# Define Azure virtual network module
module "azure_vnet" {
  source = "../azure-vnet"

  name                = "azure-vnet-${var.environment}"
  resource_group_name = module.azure_rg.name
  location            = var.azure_region
  address_space       = ["10.0.0.0/16"]
}

# Define Google VPC module
module "google_vpc" {
  source = "../google-vpc"

  name    = "google-vpc-${var.environment}"
  project = var.google_project

  auto_create_subnetworks = false
}

# Define Google subnet module
module "google_subnet" {
  source = "../google-subnet"

  name          = "google-subnet-${var.environment}"
  project       = var.google_project
  network       = module.google_vpc.self_link
  ip_cidr_range = "10.0.1.0/24"
  region        = var.google_region
}