variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets to use for the node group"
}

variable "instance_types" {
  type        = list(string)
  description = "The instance types to use for the node group"
}

variable "node_group_name" {
  type        = string
  description = "The name of the node group"
}

variable "node_group_instance_labels" {
  type        = map(string)
  description = "The labels to apply to the node group instances"
}

variable "node_group_taints" {
  type        = list(object({ key = string, value = string, effect = string }))
  description = "The taints to apply to the node group instances"
}

variable "node_group_tags" {
  type        = map(string)
  description = "The tags to apply to the node group instances"
}

variable "scaling_config" {
  type = object({
    desired_size = number
    max_size     = number
    min_size     = number
  })
  description = "The scaling configuration for the node group"
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn

  subnet_ids = var.subnet_ids

  instance_types = var.instance_types

  labels = var.node_group_instance_labels

  taint {
    key    = var.node_group_taints[0].key
    value  = var.node_group_taints[0].value
    effect = var.node_group_taints[0].effect
  }

  tags = var.node_group_tags

  scaling_config {
    desired_size = var.scaling_config.desired_size
    max_size     = var.scaling_config.max_size
    min_size     = var.scaling_config.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
  ]
}

resource "aws_iam_role" "eks_node" {
  name        = "eks-node"
  description = "EKS node role"

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