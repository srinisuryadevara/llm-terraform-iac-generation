provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "pipeline_name" {
  type        = string
  description = "Pipeline Name"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "iam_role_arn" {
  type        = string
  description = "IAM Role ARN"
}

variable "iam_policy_arn" {
  type        = string
  description = "IAM Policy ARN"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name        = "${var.pipeline_name}-codepipeline-role"
  description = "IAM Role for CodePipeline"

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

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "${var.pipeline_name}-codepipeline-policy"
  description = "IAM Policy for CodePipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
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

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
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
      version         = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName = var.pipeline_name
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
      version         = "1"
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
      version         = "1"
      input_artifacts = ["build"]

      configuration = {
        ActionMode     = "CREATE_UPDATE"
        Capabilities  = "CAPABILITY_IAM,CAPABILITY_AUTO_EXPAND"
        OutputFileName = "CreateStackOutput.json"
        RoleArn        = var.iam_role_arn
        StackName      = var.pipeline_name
        TemplatePath   = "build::template.yaml"
      }
    }
  }
}