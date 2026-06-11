provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
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
  description = "ARN of the IAM role for the pipeline"
}

variable "iam_role_policy_arn" {
  type        = string
  description = "ARN of the IAM role policy for the pipeline"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name        = "${var.pipeline_name}-codepipeline-role"
  description = "IAM role for the codepipeline"

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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.pipeline_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*"
        ]
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_codepipeline" "pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

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
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP"
        PollForSourceChanges = "false"
        RepositoryName       = var.pipeline_name
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
        ProjectName = var.pipeline_name
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
        Capabilities  = "CAPABILITY_IAM,CAPABILITY_AUTO_EXPAND"
        OutputFileName = "CreateStackOutput.json"
        RoleArn        = aws_iam_role.codepipeline_role.arn
        StackName      = var.pipeline_name
        TemplatePath   = "build::template.yaml"
      }
    }
  }
}