provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "pipeline_name" {
  type        = string
  default     = "example-pipeline"
}

variable "bucket_name" {
  type        = string
  default     = "example-bucket"
}

variable "iam_role_arn" {
  type        = string
  sensitive   = true
}

variable "iam_role_name" {
  type        = string
  default     = "example-iam-role"
}

variable "iam_policy_name" {
  type        = string
  default     = "example-iam-policy"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket        = var.bucket_name
  force_destroy = true
  tags = {
    Name        = var.bucket_name
    Environment = "example"
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name        = var.iam_role_name
  description = "IAM role for AWS CodePipeline"
  tags = {
    Name        = var.iam_role_name
    Environment = "example"
  }

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
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = var.iam_policy_name
  description = "IAM policy for AWS CodePipeline"
  tags = {
    Name        = var.iam_policy_name
    Environment = "example"
  }

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
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
        ]
        Resource = "*"
        Effect    = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_codepipeline" "example" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn
  tags = {
    Name        = var.pipeline_name
    Environment = "example"
  }

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
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["build"]

      configuration = {
        ActionMode     = "CREATE_UPDATE"
        StackName      = "example-stack"
        Capabilities   = "CAPABILITY_IAM,CAPABILITY_AUTO_EXPAND"
        TemplatePath   = "build::template.yaml"
      }
    }
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.artifact_store.bucket
  description = "The name of the S3 bucket used as the artifact store"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.artifact_store.arn
  description = "The ARN of the S3 bucket used as the artifact store"
}

output "iam_role_name" {
  value       = aws_iam_role.codepipeline_role.name
  description = "The name of the IAM role used by the CodePipeline"
}

output "iam_role_arn" {
  value       = aws_iam_role.codepipeline_role.arn
  description = "The ARN of the IAM role used by the CodePipeline"
}

output "codepipeline_name" {
  value       = aws_codepipeline.example.name
  description = "The name of the CodePipeline"
}

output "codepipeline_arn" {
  value       = aws_codepipeline.example.arn
  description = "The ARN of the CodePipeline"
}