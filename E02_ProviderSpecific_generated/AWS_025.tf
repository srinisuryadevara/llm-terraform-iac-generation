provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "pipeline_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "service_role_name" {
  type = string
}

variable "artifact_store_name" {
  type = string
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_service_role" {
  name        = var.service_role_name
  description = "Service role for CodePipeline"

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
  name        = "codepipeline-policy"
  description = "Policy for CodePipeline"

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
        Action = "codepipeline:*"
        Resource = "*"
        Effect    = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_codepipeline" "pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_service_role.arn

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
        Capabilities   = "CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        RoleArn        = aws_iam_role.codepipeline_service_role.arn
        StackName      = "example-stack"
        TemplatePath   = "build::template.yaml"
      }
    }
  }
}