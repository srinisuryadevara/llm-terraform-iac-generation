# Variables
variable "lb_name" {
  type        = string
  description = "The name of the load balancer"
}

variable "internal" {
  type        = bool
  description = "Whether the load balancer is internal or not"
}

variable "lb_type" {
  type        = string
  description = "The type of load balancer"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets"
}

variable "lb_port" {
  type        = number
  description = "The port of the load balancer"
}

variable "lb_protocol" {
  type        = string
  description = "The protocol of the load balancer"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "instance_ids" {
  type        = list(string)
  description = "The IDs of the instances"
}

variable "app_vpc_cidr_block" {
  type        = string
  description = "The CIDR block of the VPC"
}

variable "sys_name" {
  type        = string
  description = "The name of the system"
}

variable "sys_vpc_cidr_block" {
  type        = string
  description = "The CIDR block of the system VPC"
}

# Load balancer
resource "aws_lb" "main" {
  name               = var.lb_name
  internal           = var.internal
  load_balancer_type = var.lb_type
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
}

# Target group for instances
resource "aws_lb_target_group" "main" {
  port     = var.lb_port
  protocol = var.lb_protocol
  vpc_id   = var.vpc_id
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "main" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.main.arn
  port             = var.lb_port
  target_id        = var.instance_ids[count.index]
}

# Listener for ALB
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.lb_port
  protocol          = var.lb_protocol

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}

# Listener rule for path-based routing
resource "aws_lb_listener_rule" "path_based" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["/path/*"]
    }
  }
}

# VPC resources
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.app_vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "app-vpc"
  }
}

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "app-igw"
  }
}

resource "aws_route_table" "app_public_rtb" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "app-public-rtb"
  }
}

resource "aws_route" "app_public_rtb_igw_r" {
  route_table_id         = aws_route_table.app_public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_igw.id
}

locals {
  # Assign a number to each AZ letter used in public subnets
  pub_az_number = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }

  # Assign a number to each AZ letter used in private subnets
  pvt_az_number = {
    a = 7
    b = 8
    c = 9
    d = 10
    e = 11
    f = 12
  }
}

# Determine all of the available availability zones in the current AWS region.
data "aws_availability_zones" "available" {
  state = "available"
}

# This additional data source determines some additional details about each VPC, 
# including its suffix letter.
data "aws_availability_zone" "all" {
  for_each = toset(data.aws_availability_zones.available.names)

  name = each.key
}

resource "aws_subnet" "app_public_subnets" {
  for_each = data.aws_availability_zone.all

  vpc_id                  = aws_vpc.app_vpc.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.app_vpc.cidr_block, 4, local.pub_az_number[each.key[-1:]])
  map_public_ip_on_launch = true

  tags = {
    Name = "app-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "app_private_subnets" {
  for_each = data.aws_availability_zone.all

  vpc_id                  = aws_vpc.app_vpc.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.app_vpc.cidr_block, 4, local.pvt_az_number[each.key[-1:]])
  map_public_ip_on_launch = false

  tags = {
    Name = "app-private-subnet-${each.key}"
  }
}