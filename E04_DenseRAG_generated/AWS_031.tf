# Configure the AWS Provider
provider "aws" {
  version = "~> 3.0"
  region  = var.region

  assume_role {
    role_arn = var.eks_role_arn
  }
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_id
    ]
  }
}

# Configure the Helm Provider
provider "helm" {
  version = ">= 2.1"
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_id
      ]
    }
  }
}

# Create the EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    "${var.cluster_node_group_name}" = {
      desired_size   = 2
      min_size       = 2
      max_size       = 5
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }
}

# Create the VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

# Create the IAM Roles
resource "aws_iam_role" "eks_cluster" {
  name        = "${var.cluster_name}-eks-cluster"
  description = "EKS Cluster IAM Role"

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

resource "aws_iam_role" "eks_node" {
  name        = "${var.cluster_name}-eks-node"
  description = "EKS Node IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

# Create the IAM Policies
resource "aws_iam_policy" "eks_cluster" {
  name        = "${var.cluster_name}-eks-cluster-policy"
  description = "EKS Cluster IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*",
          "iam:PassRole",
          "ec2:*",
          "elasticloadbalancing:*",
          "cloudwatch:*"
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "eks_node" {
  name        = "${var.cluster_name}-eks-node-policy"
  description = "EKS Node IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "cloudwatch:*"
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })
}

# Attach the IAM Policies to the IAM Roles
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = aws_iam_policy.eks_cluster.arn
}

resource "aws_iam_role_policy_attachment" "eks_node" {
  role       = aws_iam_role.eks_node.name
  policy_arn = aws_iam_policy.eks_node.arn
}

# Get the available Availability Zones
data "aws_availability_zones" "available" {}

# Get the current AWS Caller Identity
data "aws_caller_identity" "current" {}

# Define the input variables
variable "region" {
  type        = string
  description = "The AWS region to create the EKS cluster in"
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "The version of the EKS cluster"
}

variable "cluster_node_group_name" {
  type        = string
  description = "The name of the EKS node group"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC"
}

variable "private_subnets" {
  type        = list(string)
  description = "The private subnets of the VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "The public subnets of the VPC"
}

variable "eks_role_arn" {
  type        = string
  description = "The ARN of the EKS role"
}