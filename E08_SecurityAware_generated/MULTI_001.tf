# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a VPC on AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
  tags = {
    Name        = "aws-vpc"
    Environment = var.environment
  }
}

# Create a subnet on AWS
resource "aws_subnet" "aws_subnet" {
  cidr_block = var.aws_subnet_cidr
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = var.aws_availability_zone
  tags = {
    Name        = "aws-subnet"
    Environment = var.environment
  }
}

# Create a security group on AWS
resource "aws_security_group" "aws_sg" {
  name        = "aws-sg"
  description = "Allow inbound traffic on port 22 from specific CIDR"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "Allow SSH from specific CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_sg_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "aws-sg"
    Environment = var.environment
  }
}

# Create an EKS cluster on AWS
resource "aws_eks_cluster" "aws_eks_cluster" {
  name     = "aws-eks-cluster"
  role_arn = aws_iam_role.aws_eks_role.arn

  vpc_config {
    security_group_ids = [aws_security_group.aws_sg.id]
    subnet_ids         = [aws_subnet.aws_subnet.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.aws_eks-AmazonEKSVPCResourceController,
  ]

  tags = {
    Name        = "aws-eks-cluster"
    Environment = var.environment
  }
}

# Create an IAM role for EKS on AWS
resource "aws_iam_role" "aws_eks_role" {
  name        = "aws-eks-role"
  description = "EKS role"

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

  tags = {
    Name        = "aws-eks-role"
    Environment = var.environment
  }
}

# Create an IAM policy attachment for EKS on AWS
resource "aws_iam_role_policy_attachment" "aws_eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.aws_eks_role.name
}

# Create an IAM policy attachment for EKS on AWS
resource "aws_iam_role_policy_attachment" "aws_eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.aws_eks_role.name
}

# Create a resource group on Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = "azure-rg"
  location = var.azure_location
  tags = {
    Name        = "azure-rg"
    Environment = var.environment
  }
}

# Create a virtual network on Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Name        = "azure-vnet"
    Environment = var.environment
  }
}

# Create a subnet on Azure
resource "azurerm_subnet" "azure_subnet" {
  name                 = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure_rg.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_cidr]
  tags = {
    Name        = "azure-subnet"
    Environment = var.environment
  }
}

# Create a network security group on Azure
resource "azurerm_network_security_group" "azure_nsg" {
  name                = "azure-nsg"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Name        = "azure-nsg"
    Environment = var.environment
  }
}

# Create a network security rule on Azure
resource "azurerm_network_security_rule" "azure_nsr" {
  name                        = "azure-nsr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.azure_nsg_cidr
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.azure_rg.name
  network_security_group_name = azurerm_network_security_group.azure_nsg.name
}

# Create an AKS cluster on Azure
resource "azurerm_kubernetes_cluster" "azure_aks_cluster" {
  name                = "azure-aks-cluster"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  dns_prefix          = "azure-aks-dns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    Name        = "azure-aks-cluster"
    Environment = var.environment
  }
}

# Create a project on GCP
resource "google_project" "gcp_project" {
  project_id = var.gcp_project_id
  name       = var.gcp_project_name
  tags = {
    Name        = "gcp-project"
    Environment = var.environment
  }
}

# Create a VPC on GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
  project                 = google_project.gcp_project.project_id
  tags = {
    Name        = "gcp-vpc"
    Environment = var.environment
  }
}

# Create a subnet on GCP
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  network       = google_compute_network.gcp_vpc.id
  project       = google_project.gcp_project.project_id
  tags = {
    Name        = "gcp-subnet"
    Environment = var.environment
  }
}

# Create a firewall rule on GCP
resource "google_compute_firewall" "gcp_fw" {
  name    = "gcp-fw"
  network = google_compute_network.gcp_vpc.id
  project = google_project.gcp_project.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.gcp_fw_cidr]
  tags = {
    Name        = "gcp-fw"
    Environment = var.environment
  }
}

# Create a GKE cluster on GCP
resource "google_container_cluster" "gcp_gke_cluster" {
  name               = "gcp-gke-cluster"
  location           = var.gcp_location
  project            = google_project.gcp_project.project_id
  network            = google_compute_network.gcp_vpc.id
  subnetwork         = google_compute_subnetwork.gcp_subnet.id
  min_master_version = "1.21.5-gke.1302"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So, create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  tags = {
    Name        = "gcp-gke-cluster"
    Environment = var.environment
  }
}