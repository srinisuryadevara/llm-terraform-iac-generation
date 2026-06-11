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

# Configure the Kubernetes Provider for GCP
provider "kubernetes" {
  alias                  = "gke"
  host                   = module.gke.endpoint
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)

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

# Define locals for AWS
locals {
  aws_name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  aws_cluster_version = "1.22"
  aws_region          = var.aws_region

  aws_tags = {
    Example    = local.aws_name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

# Define locals for Azure
locals {
  azure_name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  azure_cluster_version = "1.22"
  azure_location        = var.azure_location

  azure_tags = {
    Example    = local.azure_name
    GithubRepo = "terraform-azurerm-aks"
    GithubOrg  = "terraform-azurerm-modules"
  }
}

# Define locals for GCP
locals {
  gcp_name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  gcp_cluster_version = "1.22"
  gcp_region          = var.google_region

  gcp_tags = {
    Example    = local.gcp_name
    GithubRepo = "terraform-google-gke"
    GithubOrg  = "terraform-google-modules"
  }
}

# Create an EKS cluster
module "eks" {
  source = "../.."

  cluster_name                    = local.aws_name
  cluster_version                 = local.aws_cluster_version
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

# Create an AKS cluster
module "aks" {
  source = "../../aks"

  resource_group_name = module.resource_group.name
  location            = local.azure_location
  cluster_name        = local.azure_name
  cluster_version     = local.azure_cluster_version

  network_profile = {
    network_plugin = "azure"
  }

  default_node_pool = {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_DS2_v2"
  }
}

# Create a GKE cluster
module "gke" {
  source = "../../gke"

  project_id = var.google_project
  name       = local.gcp_name
  location   = local.gcp_region
  network    = module.vpc.network

  node_pools = [
    {
      name       = "default"
      node_count = 3
      machine_type = "n1-standard-1"
    },
  ]
}

# Create a VPC for AWS
module "vpc" {
  source = "../.."

  name = local.aws_name
  cidr = "10.0.0.0/16"

  azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = local.aws_tags
}

# Create a resource group for Azure
module "resource_group" {
  source = "../.."

  name     = local.azure_name
  location = local.azure_location

  tags = local.azure_tags
}

# Create a VPC for GCP
module "vpc" {
  source = "../.."

  project_id = var.google_project
  name       = local.gcp_name
  routing_mode = "REGIONAL"

  subnets = [
    {
      name           = "subnet-1"
      ip_cidr_range = "10.0.1.0/24"
      region        = local.gcp_region
    },
    {
      name           = "subnet-2"
      ip_cidr_range = "10.0.2.0/24"
      region        = local.gcp_region
    },
    {
      name           = "subnet-3"
      ip_cidr_range = "10.0.3.0/24"
      region        = local.gcp_region
    },
  ]

  tags = local.gcp_tags
}

# Create a KMS key for AWS
resource "aws_kms_key" "eks" {
  description             = "EKS KMS Key"
  deletion_window_in_days = 10
}

# Create a service principal for Azure
resource "azurerm_service_principal" "aks" {
  name = local.azure_name
}

# Create a service account for GCP
resource "google_service_account" "gke" {
  account_id = local.gcp_name
}