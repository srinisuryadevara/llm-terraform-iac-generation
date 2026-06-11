variable "cluster_name" {
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  type        = list(string)
  sensitive   = true
}

variable "node_group_name" {
  type        = string
  sensitive   = true
}

variable "instance_types" {
  type        = list(string)
  sensitive   = true
}

variable "node_group_instance_type" {
  type        = string
  sensitive   = true
}

variable "node_group_desired_size" {
  type        = number
  sensitive   = true
}

variable "node_group_max_size" {
  type        = number
  sensitive   = true
}

variable "node_group_min_size" {
  type        = number
  sensitive   = true
}

variable "node_group_capacity_type" {
  type        = string
  sensitive   = true
}

variable "node_group_labels" {
  type        = map(string)
  sensitive   = true
}

variable "node_group_taints" {
  type        = list(object({ key = string, value = string, effect = string }))
  sensitive   = true
}

variable "node_group_tags" {
  type        = map(string)
  sensitive   = true
}

variable "node_group_update_config" {
  type = object({
    max_unavailable = number
  })
  sensitive = true
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn

  subnet_ids = var.subnet_ids

  instance_types = var.instance_types

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  capacity_type = var.node_group_capacity_type

  labels = var.node_group_labels

  dynamic "taint" {
    for_each = var.node_group_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = var.node_group_tags

  update_config {
    max_unavailable = var.node_group_update_config.max_unavailable
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "eks_node" {
  name        = "eks-node"
  description = "EKS Node Role"
  tags = {
    Name        = "eks-node"
    Environment = "dev"
  }

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

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
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

output "node_role_arn" {
  value       = aws_iam_role.eks_node.arn
  description = "The ARN of the EKS node role"
}