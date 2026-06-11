provider "aws" {
  version = "~> 3.0"
  region  = var.region
}

terraform {
  backend "s3" {
    key     = "eks-cluster"
    encrypt = true
  }
}

locals {
  cluster_name = "eks-cluster-${var.environment}"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eks" {
  description = "EKS Secret Encryption Key"
}

resource "aws_iam_role" "eks" {
  name        = "eks-cluster-role"
  description = "EKS Cluster Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks_service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks.name
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_version = var.cluster_version
  cluster_name    = local.cluster_name
  vpc_id          = var.vpc_id
  subnets         = var.subnet_ids

  cluster_create_timeout                         = "1h"
  cluster_endpoint_private_access                = true
  cluster_create_endpoint_private_access_sg_rule = true
  cluster_endpoint_private_access_cidrs          = var.private_cidrs
  cluster_endpoint_public_access                 = false
  enable_irsa                                    = true

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  worker_groups = [
    {
      name          = "worker-group-1"
      instance_type = var.instance_type
      asg_max_size  = var.asg_max_size
    }
  ]
}

output "cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}