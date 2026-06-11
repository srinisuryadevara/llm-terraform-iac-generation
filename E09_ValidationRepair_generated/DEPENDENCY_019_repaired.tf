provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for EKS node group"
}

variable "node_group_name" {
  type        = string
  description = "EKS Node Group Name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for EKS node group"
}

variable "node_group_instance_type" {
  type        = string
  description = "Instance type for EKS node group"
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired size for EKS node group"
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum size for EKS node group"
}

variable "node_group_min_size" {
  type        = number
  description = "Minimum size for EKS node group"
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = var.instance_types

  tags = {
    Name        = var.node_group_name
    Environment = "eks"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
  ]
}

resource "aws_iam_role" "eks_node" {
  name        = "eks-node-role"
  description = "EKS Node Role"

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

  tags = {
    Name        = "eks-node-role"
    Environment = "eks"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name

  tags = {
    Name        = "eks-node-AmazonEKSWorkerNodePolicy"
    Environment = "eks"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name

  tags = {
    Name        = "eks-node-AmazonEC2ContainerRegistryReadOnly"
    Environment = "eks"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name

  tags = {
    Name        = "eks-node-AmazonEKS_CNI_Policy"
    Environment = "eks"
  }
}

output "node_group_id" {
  value       = aws_eks_node_group.this.id
  description = "The ID of the EKS node group"
}

output "node_group_arn" {
  value       = aws_eks_node_group.this.arn
  description = "The ARN of the EKS node group"
}

output "node_group_status" {
  value       = aws_eks_node_group.this.status
  description = "The status of the EKS node group"
}

output "eks_node_role_arn" {
  value       = aws_iam_role.eks_node.arn
  description = "The ARN of the EKS node role"
}