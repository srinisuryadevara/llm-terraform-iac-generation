# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create an AWS S3 bucket
resource "aws_s3_bucket" "aws_bucket" {
  bucket        = var.aws_bucket_name
  force_destroy = true

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Add meaningful tags
  tags = {
    Name        = "AWS S3 Bucket"
    Environment = var.environment
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  region          = var.azure_region
}

# Create an Azure Storage Account
resource "azurerm_storage_account" "azure_storage" {
  name                     = var.azure_storage_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable server-side encryption by default
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  # Add meaningful tags
  tags = {
    Name        = "Azure Storage Account"
    Environment = var.environment
  }
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a GCP Cloud Storage bucket
resource "google_storage_bucket" "gcp_bucket" {
  name                        = var.gcp_bucket_name
  location                    = var.gcp_region
  force_destroy               = true
  uniform_bucket_level_access = true

  # Enable server-side encryption by default
  encryption {
    default_kms_key_name = var.gcp_kms_key_name
  }

  # Add meaningful tags
  labels = {
    Name        = "GCP Cloud Storage Bucket"
    Environment = var.environment
  }
}

# Create a security group for AWS EC2 instances
resource "aws_security_group" "aws_sg" {
  name        = "aws_sg"
  description = "Security group for AWS EC2 instances"
  vpc_id      = var.aws_vpc_id

  # Restrict SSH access to a specific CIDR
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_ssh_cidr]
  }

  # Add meaningful tags
  tags = {
    Name        = "AWS Security Group"
    Environment = var.environment
  }
}

# Create a network security group for Azure VMs
resource "azurerm_network_security_group" "azure_nsg" {
  name                = "azure_nsg"
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  # Restrict SSH access to a specific CIDR
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.azure_ssh_cidr
    destination_address_prefix = "*"
  }

  # Add meaningful tags
  tags = {
    Name        = "Azure Network Security Group"
    Environment = var.environment
  }
}

# Create a firewall rule for GCP VMs
resource "google_compute_firewall" "gcp_fw" {
  name    = "gcp-fw"
  network = var.gcp_network

  # Restrict SSH access to a specific CIDR
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.gcp_ssh_cidr]

  # Add meaningful tags
  labels = {
    Name        = "GCP Firewall Rule"
    Environment = var.environment
  }
}