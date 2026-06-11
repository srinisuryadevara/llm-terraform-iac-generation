provider "aws" {
  region = var.region
}

locals {
  tags = {
    project = "terraform-aws-codepipeline"
    repo    = "https://github.com/your-repo/terraform-aws-codepipeline"
    region  = var.region
    env     = var.env
  }
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment"
}

variable "github_repository_owner" {
  type        = string
  description = "GitHub repository owner"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch"
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

variable "aws_account_id" {
  type        = string
  description = "AWS account ID"
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.env}-codepipeline-artifact-store-${var.region}-${var.aws_account_id}"
  acl    = "private"

  force_destroy = true
}

resource "aws_iam_role" "codepipeline" {
  name        = "CodePipelineRole-${var.env}"
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

resource "aws_iam_policy" "codepipeline" {
  name        = "CodePipelinePolicy-${var.env}"
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
          "codebuild:StopBuild",
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
          "ecs:ListTaskDefinitions",
          "ecs:ListTasks",
        ]
        Resource = "*"
        Effect    = "Allow"
      },
      {
        Action = [
          "iam:PassRole",
        ]
        Resource = "*"
        Effect    = "Allow"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "cloudformation.amazonaws.com",
              "elasticbeanstalk.amazonaws.com",
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com",
            ]
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_codestarconnections_connection" "this" {
  name          = "github-connection-${var.env}"
  provider_type = "GitHub"
}

resource "aws_codebuild_project" "this" {
  name        = "codebuild-project-${var.env}"
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

resource "aws_iam_role" "codebuild" {
  name        = "CodeBuildRole-${var.env}"
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

resource "aws_iam_policy" "codebuild" {
  name        = "CodeBuildPolicy-${var.env}"
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

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

resource "aws_codepipeline" "this" {
  name     = "${var.env}-codepipeline"
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