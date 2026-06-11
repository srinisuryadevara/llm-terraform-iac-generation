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
}

resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "eks" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.eks.id
  availability_zone = "us-west-2a"
}

data "aws_iam_policy_document" "eks_node" {
  statement {
    actions = [
      "ec2:Describe*",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeRegions",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeImages",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSnapshotAttribute",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeNetworkAclAttribute",
      "ec2:DescribeRouteTables",
      "ec2:DescribeRouteTableAttribute",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcEndpoint",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcPeeringConnection",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribePrefixLists",
      "ec2:DescribePrefixListAttribute",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeReservedInstances",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeReservedInstancesListings",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotFleetRequestHistory",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeTags",
      "ec2:DescribeVolumeQueue",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpc",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcEndpoint",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcPeeringConnection",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribePrefixLists",
      "ec2:DescribePrefixListAttribute",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeReservedInstances",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeReservedInstancesListings",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotFleetRequestHistory",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeTags",
      "ec2:DescribeVolumeQueue",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpc",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcEndpoint",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcPeeringConnection",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribePrefixLists",
      "ec2:DescribePrefixListAttribute",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeReservedInstances",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeReservedInstancesListings",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotFleetRequestHistory",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeTags",
      "ec2:DescribeVolumeQueue",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpc",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcEndpoint",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcPeeringConnection",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribePrefixLists",
      "ec2:DescribePrefixListAttribute",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeReservedInstances",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeReservedInstancesListings",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotFleetRequestHistory",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeTags",
      "ec2:DescribeVolumeQueue",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpc",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcEndpoint",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcPeeringConnection",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribePrefixLists",
      "ec2:DescribePrefixListAttribute",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeReservedInstances",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeReservedInstancesListings",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotFleetRequestHistory",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeTags",
      "ec2:DescribeVolumeQueue",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpc",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcEndpoint",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcPeeringConnection",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribePrefixLists",
      "ec2