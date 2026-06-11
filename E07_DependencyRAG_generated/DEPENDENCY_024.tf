provider "aws" {
  region = var.region
}

resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.example.arn
  subnet_ids      = aws_subnet.example.*.id

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_cluster" "example" {
  name     = var.cluster_name
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = aws_subnet.example.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "example" {
  name        = var.iam_role_name
  description = "EKS Node Group IAM Role"

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

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.example.name
}

resource "aws_subnet" "example" {
  count = var.subnet_count

  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "node_group_name" {
  type        = string
  description = "EKS Node Group Name"
}

variable "desired_size" {
  type        = number
  description = "Desired size of the EKS Node Group"
}

variable "max_size" {
  type        = number
  description = "Maximum size of the EKS Node Group"
}

variable "min_size" {
  type        = number
  description = "Minimum size of the EKS Node Group"
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for the EKS Node Group"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "iam_role_name" {
  type        = string
  description = "IAM Role Name for the EKS Node Group"
}

variable "subnet_count" {
  type        = number
  description = "Number of subnets to create"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}