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

variable "node_group_name" {
  type        = string
  description = "EKS Node Group Name"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
}

variable "node_group_size" {
  type        = number
  description = "Number of nodes in the node group"
}

data "aws_iam_policy_document" "eks_cluster" {
  statement {
    actions = [
      "eks:*",
      "iam:PassRole",
      "ec2:*",
      "elasticloadbalancing:*",
      "cloudwatch:*"
    ]
    resources = ["*"]
  }
}

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

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role        = aws_iam_role.eks_cluster.name
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

resource "aws_iam_role_policy_attachment" "eks_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role        = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role        = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role        = aws_iam_role.eks_node.name
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks.id]
    subnet_ids         = [aws_subnet.eks.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster
  ]
}

resource "aws_security_group" "eks" {
  name        = "${var.cluster_name}-eks-sg"
  description = "EKS Security Group"
  vpc_id      = aws_vpc.eks.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "eks" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.eks.id
  availability_zone = "us-west-2a"
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids     = [aws_subnet.eks.id]

  scaling_config {
    desired_size = var.node_group_size
    max_size     = var.node_group_size
    min_size     = var.node_group_size
  }

  instance_types = [var.instance_type]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node,
    aws_iam_role_policy_attachment.eks_node_container_registry,
    aws_iam_role_policy_attachment.eks_node_cni,
  ]
}