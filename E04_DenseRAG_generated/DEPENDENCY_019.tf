provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

locals {
  node_group_name = "eks-node-group"
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = local.node_group_name
  node_role_arn   = var.node_role_arn

  subnet_ids = var.subnet_ids

  instance_types = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  depends_on = [
    var.cluster_name,
    var.subnet_ids,
  ]
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "cluster_endpoint" {
  type        = string
  description = "The endpoint of the EKS cluster"
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "The certificate authority data of the EKS cluster"
}

variable "node_role_arn" {
  type        = string
  description = "The ARN of the node role"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets"
}

variable "instance_types" {
  type        = list(string)
  description = "The instance types for the node group"
}

variable "desired_size" {
  type        = number
  description = "The desired size of the node group"
}

variable "max_size" {
  type        = number
  description = "The maximum size of the node group"
}

variable "min_size" {
  type        = number
  description = "The minimum size of the node group"
}

variable "region" {
  type        = string
  description = "The AWS region"
}