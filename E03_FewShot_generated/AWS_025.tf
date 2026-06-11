provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "pipeline_name" {
  type        = string
  description = "CodePipeline name"
}

variable "artifact_bucket_name" {
  type        = string
  description = "S3 bucket name for artifact store"
}

variable "source_output_artifact" {
  type        = string
  description = "Source output artifact name"
}

variable "build_output_artifact" {
  type        = string
  description = "Build output artifact name"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token"
}

variable "github_repo_owner" {
  type        = string
  description = "GitHub repository owner"
}

variable "github_repo_name" {
  type        = string
  description = "GitHub repository name"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = var.artifact_bucket_name
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
}

resource "aws_iam_role" "codepipeline" {
  name        = "${var.pipeline_name}-codepipeline"
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

resource "aws_iam_role_policy" "codepipeline" {
  name   = "${var.pipeline_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline.id
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
          "codebuild:BatchGetProjects",
          "codebuild:StartBuild",
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
      },
    ]
  })
}

resource "aws_iam_role" "codebuild" {
  name        = "${var.pipeline_name}-codebuild"
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

resource "aws_iam_role_policy" "codebuild" {
  name   = "${var.pipeline_name}-codebuild-policy"
  role   = aws_iam_role.codebuild.id
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
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*",
        ]
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_codepipeline" "pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifact_store.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = [var.source_output_artifact]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = [var.source_output_artifact]
      output_artifacts = [var.build_output_artifact]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.pipeline_name}-github-connection"
  provider_type = "GitHub"
}

resource "aws_codebuild_project" "build" {
  name        = "${var.pipeline_name}-build"
  description = "CodeBuild project for ${var.pipeline_name}"

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