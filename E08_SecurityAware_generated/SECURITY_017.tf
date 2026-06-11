provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDRs"
}

variable "eks_node_instance_type" {
  type        = string
  description = "EKS Node Instance Type"
}

variable "eks_node_group_name" {
  type        = string
  description = "EKS Node Group Name"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "eks-vpc"
    Environment = "prod"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  cidr_block        = var.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.this.id
  availability_zone = "${var.aws_region}${count.index % 3 + 1}"
  tags = {
    Name        = "eks-private-subnet-${count.index}"
    Environment = "prod"
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster.id]
    subnet_ids         = aws_subnet.private.*.id
  }
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }
  tags = {
    Name        = "eks-cluster"
    Environment = "prod"
  }
}

resource "aws_kms_key" "eks" {
  description             = "EKS Envelope Encryption Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags = {
    Name        = "eks-envelope-encryption-key"
    Environment = "prod"
  }
}

resource "aws_iam_role" "eks_cluster" {
  name        = "eks-cluster-role"
  description = "EKS Cluster Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Effect = "Allow"
        Sid      = ""
      }
    ]
  })
  tags = {
    Name        = "eks-cluster-role"
    Environment = "prod"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-sg"
  description = "EKS Cluster Security Group"
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
    Name        = "eks-cluster-sg"
    Environment = "prod"
  }
}

resource "aws_iam_role" "eks_node" {
  name        = "eks-node-role"
  description = "EKS Node Role"
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
  tags = {
    Name        = "eks-node-role"
    Environment = "prod"
  }
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

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private.*.id
  instance_types = [var.eks_node_instance_type]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
  ]
  tags = {
    Name        = "eks-node-group"
    Environment = "prod"
  }
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws_region}.eks"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.eks_cluster.id
  ]
  subnet_ids = aws_subnet.private.*.id
  tags = {
    Name        = "eks-vpc-endpoint"
    Environment = "prod"
  }
}