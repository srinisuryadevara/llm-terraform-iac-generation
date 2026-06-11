provider "aws" {
  region = var.region
}

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

locals {
  name            = "eks-${var.environment}"
  cluster_version = var.cluster_version
  region          = var.region

  tags = {
    Environment = var.environment
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }
}

data "aws_caller_identity" "current" {}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the node group"
}

variable "node_group_name" {
  type        = string
  description = "Name of the node group"
}

variable "node_group_instance_count" {
  type        = number
  description = "Number of instances in the node group"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs of the subnets"
}

variable "eks_iam_role_arn" {
  type        = string
  description = "ARN of the EKS IAM role"
}

variable "node_group_iam_role_arn" {
  type        = string
  description = "ARN of the node group IAM role"
}

variable "eks_kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for EKS"
}

variable "vpc_cni_iam_role_arn" {
  type        = string
  description = "ARN of the VPC CNI IAM role"
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "../.."

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = var.vpc_cni_iam_role_arn
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = var.eks_kms_key_arn
    resources        = ["secrets"]
  }]

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Create a managed node group
  managed_node_groups = {
    example = {
      name         = var.node_group_name
      instance_type = var.instance_type
      num_instances = var.node_group_instance_count
    }
  }

  # Create the required IAM roles
  create_iam_role          = true
  iam_role_name            = var.eks_iam_role_arn
  create_iam_role_policy   = true
  iam_role_policy_name     = "eks-policy"
  create_cni_iam_role      = true
  cni_iam_role_name        = var.vpc_cni_iam_role_arn
  create_cni_iam_role_policy = true
  cni_iam_role_policy_name  = "cni-policy"
  create_node_iam_role     = true
  node_iam_role_name       = var.node_group_iam_role_arn
  create_node_iam_role_policy = true
  node_iam_role_policy_name  = "node-policy"
}