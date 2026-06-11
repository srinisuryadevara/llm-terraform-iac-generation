variable "prefix" {
  type        = string
  description = "Prefix for resources"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "github_repository_owner" {
  type        = string
  description = "GitHub repository owner"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch name"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token"
}

variable "github_connection_arn" {
  type        = string
  description = "GitHub connection ARN"
}

# Create S3 bucket for artifact store
resource "aws_s3_bucket" "this" {
  bucket        = "${var.prefix}-artifact-store"
  force_destroy = true
  acl           = "private"
}

# Create IAM role for CodePipeline
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

# Create IAM policy for CodePipeline
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
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
        ]
        Resource = "*"
        Effect    = "Allow"
      },
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListServices",
          "ecs:ListTaskDefinitionFamilies",
          "ecs:ListTasks",
        ]
        Resource = "*"
        Effect    = "Allow"
      },
    ]
  })
}

# Attach IAM policy to CodePipeline role
resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

# Create CodePipeline
resource "aws_codepipeline" "this" {
  name     = "${var.prefix}-pipeline"
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
        ConnectionArn    = var.github_connection_arn
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
        ProjectName = "${var.prefix}-build-project"
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

# Create CodeBuild project
resource "aws_codebuild_project" "this" {
  name        = "${var.prefix}-build-project"
  description = "CodeBuild project for ${var.prefix}"

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

  logs_config {
    s3_logs {
      encryption_disabled = false
      location            = "${aws_s3_bucket.this.id}/build-logs"
      status              = "ENABLED"
    }
  }

  service_role = aws_iam_role.codebuild.arn
}

# Create IAM role for CodeBuild
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

# Create IAM policy for CodeBuild
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