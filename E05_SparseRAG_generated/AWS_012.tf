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

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for managed node group"
}

variable "node_group_name" {
  type        = string
  description = "Name of the managed node group"
}

variable "node_group_instance_count" {
  type        = number
  description = "Number of instances in the managed node group"
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

variable "eks_iam_instance_profile_arn" {
  type        = string
  description = "ARN of the EKS IAM instance profile"
}

variable "node_group_iam_role_arn" {
  type        = string
  description = "ARN of the node group IAM role"
}

variable "node_group_iam_instance_profile_arn" {
  type        = string
  description = "ARN of the node group IAM instance profile"
}

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
      service_account_role_arn = var.node_group_iam_role_arn
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
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
}

resource "aws_kms_key" "eks" {
  description             = "EKS KMS key"
  deletion_window_in_days = 10
}

resource "aws_iam_role" "eks" {
  name        = "${local.name}-eks"
  description = "EKS IAM role"

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
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_instance_profile" "eks" {
  name = "${local.name}-eks"
  role = aws_iam_role.eks.name
}

module "managed_node_group" {
  source = "../.."

  cluster_name    = module.eks.cluster_name
  node_group_name = var.node_group_name
  instance_types  = [var.instance_type]
  node_count      = var.node_group_instance_count

  vpc_id  = var.vpc_id
  subnets = var.subnet_ids

  iam_role_arn = var.node_group_iam_role_arn
  iam_instance_profile_arn = var.node_group_iam_instance_profile_arn
}

resource "aws_iam_role" "node_group" {
  name        = "${local.name}-node-group"
  description = "Node group IAM role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_instance_profile" "node_group" {
  name = "${local.name}-node-group"
  role = aws_iam_role.node_group.name
}