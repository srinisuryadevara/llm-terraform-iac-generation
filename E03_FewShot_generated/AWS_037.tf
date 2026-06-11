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
  description = "EC2 Instance Type for Node Group"
}

variable "node_group_size" {
  type        = number
  description = "Number of nodes in the Node Group"
}

# Create IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name        = "${var.cluster_name}-eks-cluster"
  description = "EKS Cluster IAM Role"

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

# Attach EKS Cluster Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Create IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node" {
  name        = "${var.node_group_name}-eks-node"
  description = "EKS Node IAM Role"

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

# Attach EKS Node Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

# Attach EKS CNI Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

# Attach EC2 Container Registry Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

# Create EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks.id]
    subnet_ids         = [aws_subnet.eks.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}

# Create Security Group for EKS Cluster
resource "aws_security_group" "eks" {
  name        = "${var.cluster_name}-eks-sg"
  description = "EKS Cluster Security Group"
  vpc_id      = aws_vpc.eks.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Create VPC for EKS Cluster
resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"
}

# Create Subnet for EKS Cluster
resource "aws_subnet" "eks" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.eks.id
  availability_zone = "us-west-2a"
}

# Create EKS Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn

  subnet_ids = [aws_subnet.eks.id]

  scaling_config {
    desired_size = var.node_group_size
    max_size     = var.node_group_size
    min_size     = var.node_group_size
  }

  instance_types = [var.instance_type]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.ecr,
  ]
}