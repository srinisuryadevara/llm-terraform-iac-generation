variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets to use for the node group"
}

variable "node_instance_type" {
  type        = string
  description = "The instance type to use for the node group"
}

variable "desired_capacity" {
  type        = number
  description = "The desired capacity for the node group"
}

variable "max_size" {
  type        = number
  description = "The maximum size for the node group"
}

variable "min_size" {
  type        = number
  description = "The minimum size for the node group"
}

variable "key_name" {
  type        = string
  description = "The name of the SSH key to use for the node group"
}

variable "k8s_version" {
  type        = string
  description = "The version of Kubernetes to use for the node group"
}

provider "aws" {
  region = "eu-west-1"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.eks.name,
    ]
  }
}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_subnets" "subnets" {
  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
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

resource "aws_iam_instance_profile" "node" {
  name = "${var.cluster_name}-eks-node-instance-profile"
  role = aws_iam_role.node.name
}

resource "aws_eks_node_group" "node" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}