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
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.22"
  region          = var.region

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability Zones"
}

variable "instance_type" {
  type        = string
  description = "Instance Type"
}

variable "node_group_name" {
  type        = string
  description = "Node Group Name"
}

variable "node_group_instance_type" {
  type        = string
  description = "Node Group Instance Type"
}

variable "node_group_desired_capacity" {
  type        = number
  description = "Node Group Desired Capacity"
}

variable "node_group_max_capacity" {
  type        = number
  description = "Node Group Max Capacity"
}

variable "node_group_min_capacity" {
  type        = number
  description = "Node Group Min Capacity"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = [for az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, az))]
  private_subnets = [for az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, az) + 10)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = local.tags
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

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
  description             = "EKS KMS Key"
  deletion_window_in_days = 10
}

resource "aws_iam_role" "eks_node" {
  name        = "${local.name}-eks-node"
  description = "EKS Node IAM Role"

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

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

module "eks_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks_managed_node_group"

  name                 = var.node_group_name
  cluster_name         = module.eks.cluster_name
  instance_types       = [var.node_group_instance_type]
  node_group_name      = var.node_group_name
  node_role_arn        = aws_iam_role.eks_node.arn
  subnet_ids           = module.vpc.private_subnets
  desired_capacity     = var.node_group_desired_capacity
  max_capacity         = var.node_group_max_capacity
  min_capacity         = var.node_group_min_capacity
  force_update_version = true

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
  ]
}