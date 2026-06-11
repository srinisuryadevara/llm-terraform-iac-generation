variable "cluster_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_group_name" {
  type = string
}

variable "instance_types" {
  type = list(string)
}

variable "node_group_labels" {
  type = map(string)
}

variable "node_group_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
}

variable "node_group_tags" {
  type = map(string)
}

variable "node_group_version" {
  type = string
}

variable "node_group_desired_size" {
  type = number
}

variable "node_group_min_size" {
  type = number
}

variable "node_group_max_size" {
  type = number
}

variable "node_group_scaling_policies" {
  type = list(object({
    policy_type = string
    policy_name = string
    resource_id = string
    scalable_dimension = string
    service_namespace = string
  }))
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = var.subnet_ids

  instance_types = var.instance_types

  labels = var.node_group_labels

  taint {
    key    = var.node_group_taints[0].key
    value  = var.node_group_taints[0].value
    effect = var.node_group_taints[0].effect
  }

  tags = var.node_group_tags

  version = var.node_group_version

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }
}

resource "aws_iam_role" "node" {
  name        = "eks-node-group"
  description = "EKS Node Group Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid      = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSNodegroupPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNodegroupPolicy"
  role       = aws_iam_role.node.name
}