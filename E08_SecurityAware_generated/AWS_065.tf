provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "project_name" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH CIDR"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ECS Task Execution Role ARN"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "ECS Task Role ARN"
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB Listener ARN"
}

variable "alb_target_group_arn" {
  type        = string
  description = "ALB Target Group ARN"
}

variable "container_port" {
  type        = number
  description = "Container Port"
}

variable "container_image" {
  type        = string
  description = "Container Image"
}

variable "database_username" {
  type        = string
  description = "Database Username"
  sensitive   = true
}

variable "database_password" {
  type        = string
  description = "Database Password"
  sensitive   = true
}

variable "database_name" {
  type        = string
  description = "Database Name"
}

variable "database_instance_class" {
  type        = string
  description = "Database Instance Class"
}

variable "database_storage" {
  type        = number
  description = "Database Storage"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "this" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${count.index % 3 + 1}"
  tags = {
    Name        = "${var.project_name}-${var.environment}-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "ECS Security Group"
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
    Name        = "${var.project_name}-${var.environment}-ecs-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name        = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  description = "ECS Task Execution Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-execution-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name        = "${var.project_name}-${var.environment}-ecs-task-role"
  description = "ECS Task Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_task_definition" "this" {
  family                = "${var.project_name}-${var.environment}-ecs-task-definition"
  requires_compatibilities = [
    "FARGATE"
  ]
  network_mode          = "awsvpc"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = var.ecs_task_execution_role_arn
  task_role_arn         = var.ecs_task_role_arn
  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.environment}-ecs-container"
      image      = var.container_image
      cpu        = 10
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-definition"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.environment}-ecs-service"
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type      = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.this.*.id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = "ENABLED"
  }
  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "${var.project_name}-${var.environment}-ecs-container"
    container_port   = var.container_port
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_instance" "this" {
  identifier           = "${var.project_name}-${var.environment}-db-instance"
  instance_class       = var.database_instance_class
  engine               = "postgres"
  engine_version       = "13.4"
  username             = var.database_username
  password             = var.database_password
  database_name        = var.database_name
  storage_type         = "gp2"
  storage              = var.database_storage
  vpc_security_group_ids = [
    aws_security_group.ecs.id
  ]
  db_subnet_group_name = aws_db_subnet_group.this.name
  parameter_group_name = aws_db_parameter_group.this.name
  tags = {
    Name        = "${var.project_name}-${var.environment}-db-instance"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.this.*.id
  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project_name}-${var.environment}-db-parameter-group"
  family = "postgres13"
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
  parameter {
    name  = "ssl_min_protocol_version"
    value = "TLSv1.2"
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-db-parameter-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.environment}-s3-bucket"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name