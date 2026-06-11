provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
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
  description = "VPC CIDR"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "ecs_task_definition_name" {
  type        = string
  description = "ECS task definition name"
}

variable "alb_target_group_name" {
  type        = string
  description = "ALB target group name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_pair_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "db_username" {
  type        = string
  sensitive   = true
  description = "Database username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, 1)
  availability_zone = "${var.region}a"
  tags = {
    Name        = "${var.project}-${var.environment}-subnet"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      var.ssh_source_cidr
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-sg"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
  tags = {
    Name        = "${var.project}-${var.environment}-ecs-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_task_definition" "this" {
  family                = var.ecs_task_definition_name
  cpu                   = "1024"
  memory                = "512"
  network_mode          = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  tags = {
    Name        = "${var.project}-${var.environment}-ecs-task-definition"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name        = "${var.project}-${var.environment}-ecs-task-execution"
  description = "ECS task execution role"
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
    Name        = "${var.project}-${var.environment}-ecs-task-execution-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "ecs_task_execution" {
  name        = "${var.project}-${var.environment}-ecs-task-execution-policy"
  description = "ECS task execution policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })
  tags = {
    Name        = "${var.project}-${var.environment}-ecs-task-execution-policy"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

resource "aws_alb" "this" {
  name            = "${var.project}-${var.environment}-alb"
  subnets         = [aws_subnet.this.id]
  security_groups = [aws_security_group.this.id]
  tags = {
    Name        = "${var.project}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_target_group_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"
  tags = {
    Name        = "${var.project}-${var.environment}-alb-target-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project}-${var.environment}-ecs-service"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type      = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.this.id]
    security_groups = [aws_security_group.this.id]
    assign_public_ip = "ENABLED"
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.this.arn
    container_name   = "container"
    container_port   = 80
  }
  tags = {
    Name        = "${var.project}-${var.environment}-ecs-service"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_db_instance" "this" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name = aws_db_subnet_group.this.name
  storage_encrypted    = true
  tags = {
    Name        = "${var.project}-${var.environment}-db-instance"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.this.id]
  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-${var.environment}-s3-bucket"
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
    Name        = "${var.project}-${var.environment}-s3-bucket"
    Environment = var.environment
    Project     = var.project
  }
}