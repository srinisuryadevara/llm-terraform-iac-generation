provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "pipeline_name" {
  type        = string
  description = "Name of the pipeline"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "iam_role_arn" {
  type        = string
  description = "ARN of the IAM role for CodePipeline"
}

variable "iam_role_policy_arn" {
  type        = string
  description = "ARN of the IAM role policy for CodePipeline"
}

variable "source_output_artifact" {
  type        = string
  description = "Name of the output artifact from the source stage"
}

variable "build_output_artifact" {
  type        = string
  description = "Name of the output artifact from the build stage"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token for authentication"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch name"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = var.bucket_name
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
    Name        = var.pipeline_name
    Environment = "dev"
  }
}

resource "aws_iam_role" "codepipeline" {
  name        = "${var.pipeline_name}-codepipeline-role"
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
        Sid      = ""
      }
    ]
  })

  tags = {
    Name        = var.pipeline_name
    Environment = "dev"
  }
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

resource "aws_codepipeline" "pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = [var.source_output_artifact]

      configuration = {
        OAuthToken           = var.github_token
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = var.github_branch
        PollForSourceChanges = false
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
        ProjectName = "my-codebuild-project"
      }
    }
  }

  tags = {
    Name        = var.pipeline_name
    Environment = "dev"
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.artifact_store.bucket
  description = "Name of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.artifact_store.arn
  description = "ARN of the S3 bucket"
}

output "iam_role_name" {
  value       = aws_iam_role.codepipeline.name
  description = "Name of the IAM role"
}

output "iam_role_arn" {
  value       = aws_iam_role.codepipeline.arn
  description = "ARN of the IAM role"
}

output "codepipeline_name" {
  value       = aws_codepipeline.pipeline.name
  description = "Name of the CodePipeline"
}

output "codepipeline_arn" {
  value       = aws_codepipeline.pipeline.arn
  description = "ARN of the CodePipeline"
}