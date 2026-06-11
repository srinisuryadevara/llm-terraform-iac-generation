provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "pipeline_name" {
  type        = string
  description = "CodePipeline Name"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "iam_role_arn" {
  type        = string
  description = "IAM Role ARN"
}

variable "iam_role_policy_arn" {
  type        = string
  description = "IAM Role Policy ARN"
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
  description = "IAM Role for CodePipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
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
          "s3:GetObjectVersion",
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*",
        ]
      },
      {
        Action = [
          "codebuild:BatchGetProjects",
          "codebuild:StartBuild",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = {
    Name        = var.pipeline_name
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = var.iam_role_policy_arn
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
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      version         = "1"
      input_artifacts = ["build"]

      configuration = {
        ActionMode     = "CREATE_UPDATE"
        StackName      = "example-stack"
        Capabilities   = "CAPABILITY_IAM"
        TemplatePath   = "build::template.yaml"
        RoleArn        = var.iam_role_arn
      }
    }
  }

  tags = {
    Name        = var.pipeline_name
    Environment = "dev"
  }
}

output "s3_bucket_id" {
  value       = aws_s3_bucket.artifact_store.id
  description = "The ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.artifact_store.arn
  description = "The ARN of the S3 bucket"
}

output "iam_role_id" {
  value       = aws_iam_role.codepipeline.id
  description = "The ID of the IAM role"
}

output "iam_role_arn" {
  value       = aws_iam_role.codepipeline.arn
  description = "The ARN of the IAM role"
}

output "codepipeline_id" {
  value       = aws_codepipeline.pipeline.id
  description = "The ID of the CodePipeline"
}

output "codepipeline_arn" {
  value       = aws_codepipeline.pipeline.arn
  description = "The ARN of the CodePipeline"
}