provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH CIDR"
}

variable "artifact_bucket_name" {
  type        = string
  description = "Artifact bucket name"
}

variable "codepipeline_name" {
  type        = string
  description = "CodePipeline name"
}

variable "iam_role_name" {
  type        = string
  description = "IAM role name"
}

variable "iam_policy_name" {
  type        = string
  description = "IAM policy name"
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket        = var.artifact_bucket_name
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
    Name        = var.artifact_bucket_name
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name        = var.iam_role_name
  description = "CodePipeline IAM role"

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

resource "aws_iam_policy" "codepipeline_policy" {
  name        = var.iam_policy_name
  description = "CodePipeline IAM policy"

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
          aws_s3_bucket.artifact_bucket.arn,
          "${aws_s3_bucket.artifact_bucket.arn}/*",
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "codepipeline:StartPipelineExecution",
          "codepipeline:StopPipelineExecution",
        ]
        Resource = [
          aws_codepipeline.codepipeline.arn,
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

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_codepipeline" "codepipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
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
        Capabilities   = "CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        RoleArn        = aws_iam_role.codepipeline_role.arn
        StackName      = "example-stack"
        TemplatePath   = "build::template.yaml"
      }
    }
  }

  tags = {
    Name        = var.codepipeline_name
    Environment = var.environment
    Project     = var.project_name
  }
}