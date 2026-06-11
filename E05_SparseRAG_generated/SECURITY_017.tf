provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "instance_type" {
  type        = string
  description = "Instance Type"
}

variable "asg_max_size" {
  type        = number
  description = "ASG Max Size"
}

variable "vpn_subnet_id" {
  type        = string
  description = "VPN Subnet ID"
}

locals {
  cluster_name                  = "todo-app-${var.environment}"
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eks" {
  description = "EKS Secret Encryption Key"
}

data "aws_subnet" "vpn_subnet" {
  id = var.vpn_subnet_id
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_version = "1.21"
  cluster_name    = local.cluster_name
  vpc_id          = var.vpc_id
  subnets         = var.subnet_ids
  cluster_create_timeout                         = "1h"
  cluster_endpoint_private_access                = true
  cluster_create_endpoint_private_access_sg_rule = true
  cluster_endpoint_private_access_cidrs          = concat([data.aws_subnet.vpn_subnet.cidr_block])
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
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    }
  ]
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args        = ["--region", var.region, "eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}