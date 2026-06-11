provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "prefix" {
  type = string
}

variable "github_repository_owner" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

locals {
  tags = {
    project = "terraform-aws-codepipeline"
    region  = var.region
  }
}

# S3 bucket for artifact store
resource "aws_s3_bucket" "this" {
  bucket = "${var.prefix}-codepipeline-artifact-store"
  acl    = "private"

  versioning {
    enabled = true
  }

  force_destroy = true
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline" {
  name        = "${var.prefix}-codepipeline-role"
  description = "IAM role for CodePipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

# IAM policy for CodePipeline
resource "aws_iam_policy" "codepipeline" {
  name        = "${var.prefix}-codepipeline-policy"
  description = "IAM policy for CodePipeline"

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
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "codestar-connections:UseConnection",
        ]
        Resource = [
          aws_codestarconnections_connection.this.arn,
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
        ]
        Resource = [
          aws_codebuild_project.this.arn,
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListServices",
          "ecs:ListTaskDefinitionFamilies",
          "ecs:ListTasks",
          "ecs:CreateTaskSet",
          "ecs:UpdateService",
          "ecs:DeleteService",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeClusters",
          "ecs:ListClusters",
        ]
        Resource = [
          "*",
        ]
        Effect = "Allow"
      },
    ]
  })
}

# Attach IAM policy to CodePipeline role
resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

# CodeStar connection
resource "aws_codestarconnections_connection" "this" {
  name          = "${var.prefix}-github-connection"
  provider_type = "GitHub"
}

# CodeBuild project
resource "aws_codebuild_project" "this" {
  name        = "${var.prefix}-codebuild-project"
  description = "CodeBuild project for CodePipeline"

  source {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode = false
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  service_role = aws_iam_role.codebuild.arn
}

# IAM role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name        = "${var.prefix}-codebuild-role"
  description = "IAM role for CodeBuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

# IAM policy for CodeBuild
resource "aws_iam_policy" "codebuild" {
  name        = "${var.prefix}-codebuild-policy"
  description = "IAM policy for CodeBuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
        Effect    = "Allow"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
        Effect = "Allow"
      },
    ]
  })
}

# Attach IAM policy to CodeBuild role
resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

# CodePipeline
resource "aws_codepipeline" "this" {
  name     = "${var.prefix}-codepipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.this.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = 1
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.this.arn
        FullRepositoryId = "${var.github_repository_owner}/${var.github_repository}"
        BranchName       = var.github_branch
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
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = 1

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = 1

      configuration = {
        FileName    = "imagedefinitions.json"
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }
}