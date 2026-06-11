provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "node_group_name" {
  type        = string
  description = "EKS node group name"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for node group"
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR block for SSH access"
}

variable "eks_version" {
  type        = string
  description = "EKS version"
}

variable "node_group_instance_types" {
  type        = list(string)
  description = "List of instance types for node group"
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired size of node group"
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum size of node group"
}

variable "node_group_min_size" {
  type        = number
  description = "Minimum size of node group"
}

# Create VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

# Create subnets
resource "aws_subnet" "this" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone = "${var.region}${count.index % 2 == 0 ? "a" : "b"}"
  tags = {
    Name        = "${var.project}-${var.environment}-subnet-${count.index}"
    Environment = var.environment
    Project     = var.project
  }
}

# Create EKS cluster
resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster.id]
    subnet_ids         = aws_subnet.this.*.id
  }

  tags = {
    Name        = "${var.project}-${var.environment}-eks-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

# Create EKS cluster IAM role
resource "aws_iam_role" "eks_cluster" {
  name        = "${var.project}-${var.environment}-eks-cluster-role"
  description = "EKS cluster IAM role"

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

  tags = {
    Name        = "${var.project}-${var.environment}-eks-cluster-role"
    Environment = var.environment
    Project     = var.project
  }
}

# Create EKS cluster IAM policy
resource "aws_iam_policy" "eks_cluster" {
  name        = "${var.project}-${var.environment}-eks-cluster-policy"
  description = "EKS cluster IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-eks-cluster-policy"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach EKS cluster IAM policy to EKS cluster IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = aws_iam_policy.eks_cluster.arn
}

# Create EKS node group IAM role
resource "aws_iam_role" "eks_node_group" {
  name        = "${var.project}-${var.environment}-eks-node-group-role"
  description = "EKS node group IAM role"

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

  tags = {
    Name        = "${var.project}-${var.environment}-eks-node-group-role"
    Environment = var.environment
    Project     = var.project
  }
}

# Create EKS node group IAM policy
resource "aws_iam_policy" "eks_node_group" {
  name        = "${var.project}-${var.environment}-eks-node-group-policy"
  description = "EKS node group IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-eks-node-group-policy"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach EKS node group IAM policy to EKS node group IAM role
resource "aws_iam_role_policy_attachment" "eks_node_group" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = aws_iam_policy.eks_node_group.arn
}

# Create EKS node group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.this.*.id

  instance_types = var.node_group_instance_types

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  tags = {
    Name        = "${var.project}-${var.environment}-eks-node-group"
    Environment = var.environment
    Project     = var.project
  }
}

# Create security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      var.ssh_cidr
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-eks-cluster-sg"
    Environment = var.environment
    Project     = var.project
  }
}