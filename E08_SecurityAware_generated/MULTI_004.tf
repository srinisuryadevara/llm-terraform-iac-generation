# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create an AWS S3 bucket with server-side encryption
resource "aws_s3_bucket" "aws_bucket" {
  bucket = var.aws_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = var.aws_bucket_name
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

# Create an Azure Storage Account with server-side encryption
resource "azurerm_storage_account" "azure_storage" {
  name                     = var.azure_storage_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  tags = {
    Name        = var.azure_storage_name
    Environment = var.environment
  }
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a GCP Cloud Storage bucket with server-side encryption
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_region
  storage_class = "REGIONAL"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_self_link = var.gcp_kms_key
  }

  uniform_bucket_level_access = true

  tags = {
    Name        = var.gcp_bucket_name
    Environment = var.environment
  }
}

# Create a security group for AWS EC2 instances
resource "aws_security_group" "aws_sg" {
  name        = var.aws_sg_name
  description = "Allow inbound traffic on port 22 from a specific CIDR"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_sg_cidr]
  }

  tags = {
    Name        = var.aws_sg_name
    Environment = var.environment
  }
}

# Create a network security group for Azure VMs
resource "azurerm_network_security_group" "azure_nsg" {
  name                = var.azure_nsg_name
  location            = var.azure_region
  resource_group_name = var.azure_resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.azure_nsg_cidr
    destination_address_prefix = "*"
  }

  tags = {
    Name        = var.azure_nsg_name
    Environment = var.environment
  }
}

# Create a firewall rule for GCP VMs
resource "google_compute_firewall" "gcp_fw" {
  name    = var.gcp_fw_name
  network = var.gcp_network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.gcp_fw_cidr]

  target_tags = [var.gcp_fw_tag]

  tags = {
    Name        = var.gcp_fw_name
    Environment = var.environment
  }
}