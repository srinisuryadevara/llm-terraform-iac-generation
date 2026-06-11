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

variable "ssh_cidr" {
  type        = string
  description = "SSH CIDR"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "codepipeline_name" {
  type        = string
  description = "CodePipeline Name"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "iam_role_name" {
  type        = string
  description = "IAM Role Name"
}

variable "iam_policy_name" {
  type        = string
  description = "IAM Policy Name"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket        = var.s3_bucket_name
  force_destroy = true

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
    Name        = var.s3_bucket_name
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "codepipeline" {
  name        = var.iam_role_name
  description = "CodePipeline IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Effect = "Allow"
        Sid      = ""
      }
    ]
  })

  tags = {
    Name        = var.iam_role_name
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "codepipeline" {
  name        = var.iam_policy_name
  description = "CodePipeline IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*",
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "codepipeline:StartPipelineExecution",
          "codepipeline:StopPipelineExecution",
        ]
        Resource = [
          aws_codepipeline.pipeline.arn,
        ]
        Effect = "Allow"
      },
    ]
  })

  tags = {
    Name        = var.iam_policy_name
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_codepipeline" "pipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName = "example-repo"
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]

      configuration = {
        ProjectName = "example-project"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CloudFormation"
      version          = "1"
      input_artifacts  = ["build"]

      configuration = {
        ActionMode     = "CREATE_UPDATE"
        StackName      = "example-stack"
        Capabilities   = "CAPABILITY_IAM"
        TemplatePath   = "build::template.yaml"
        RoleArn        = aws_iam_role.codepipeline.arn
      }
    }
  }

  tags = {
    Name        = var.codepipeline_name
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "ssh" {
  name        = "ssh-sg"
  description = "SSH Security Group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ssh-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}