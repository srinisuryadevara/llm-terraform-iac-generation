provider "aws" {
  region = var.region
}

resource "aws_iam_role" "eks_node_group" {
  name        = "${var.cluster_name}-eks-node-group"
  description = "EKS node group IAM role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.instance_type]

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group,
    aws_iam_role_policy_attachment.eks_node_group_container_registry,
    aws_iam_role_policy_attachment.eks_node_group_cni,
  ]
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets to use for the node group"
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for the node group"
}

variable "desired_size" {
  type        = number
  description = "The desired number of nodes in the node group"
}

variable "max_size" {
  type        = number
  description = "The maximum number of nodes in the node group"
}

variable "min_size" {
  type        = number
  description = "The minimum number of nodes in the node group"
}

variable "region" {
  type        = string
  description = "The AWS region to use"
}