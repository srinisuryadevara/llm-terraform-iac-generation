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

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for artifact store"
}

variable "iam_role_arn" {
  type        = string
  description = "IAM role ARN for CodePipeline"
}

variable "iam_role_policy_arn" {
  type        = string
  description = "IAM role policy ARN for CodePipeline"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = var.bucket_name
  acl    = "private"
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
    ]
  })
}

resource "aws_codepipeline" "example" {
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
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP"
        PollForSourceChanges = "true"
        RepositoryName       = "example-repo"
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
        Capabilities   = "CAPABILITY_IAM,CAPABILITY_AUTO_EXPAND"
        OutputFileName = "CreateStacksOutput.json"
        RoleArn        = aws_iam_role.codepipeline.arn
        StackName      = "example-stack"
        TemplatePath   = "build::template.yaml"
      }
    }
  }
}