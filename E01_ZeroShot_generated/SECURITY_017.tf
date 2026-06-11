provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  sensitive   = false
}

variable "vpc_id" {
  type        = string
  sensitive   = false
}

variable "subnet_ids" {
  type        = list(string)
  sensitive   = false
}

variable "eks_version" {
  type        = string
  sensitive   = false
}

variable "instance_types" {
  type        = list(string)
  sensitive   = false
}

variable "node_group_name" {
  type        = string
  sensitive   = false
}

variable "node_group_instance_type" {
  type        = string
  sensitive   = false
}

variable "node_group_desired_capacity" {
  type        = number
  sensitive   = false
}

variable "node_group_min_capacity" {
  type        = number
  sensitive   = false
}

variable "node_group_max_capacity" {
  type        = number
  sensitive   = false
}

variable "kms_key_arn" {
  type        = string
  sensitive   = true
}

resource "aws_kms_key" "eks" {
  description             = "EKS KMS Key"
  deletion_window_in_days  = 10
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_iam_role" "eks" {
  name        = "${var.cluster_name}-eks-role"
  description = "EKS Cluster Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
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

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks.arn
  version  = var.eks_version

  vpc_config {
    security_group_ids = [aws_security_group.eks.id]
    subnet_ids         = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
    encrypt = true
    kms_key_id = aws_kms_key.eks.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}

resource "aws_security_group" "eks" {
  name        = "${var.cluster_name}-eks-sg"
  description = "EKS Cluster Security Group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_iam_role" "node_group" {
  name        = "${var.node_group_name}-node-group-role"
  description = "EKS Node Group Role"

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

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.node_group_instance_type]

  scaling_config {
    desired_size = var.node_group_desired_capacity
    max_size     = var.node_group_max_capacity
    min_size     = var.node_group_min_capacity
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_group-AmazonEKS_CNI_Policy,
  ]
}