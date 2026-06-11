variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "sys_name" {
  type        = string
  description = "System name"
}

variable "api_domain_name" {
  type        = string
  description = "API domain name"
}

data "aws_caller_identity" "current" {}

# S3 bucket for CodePipeline artifact store
module "codepipeline_bucket" {
  source        = "../../modules/s3-bucket"
  bucket        = "codepipeline-${var.sys_name}-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  acl           = "private"
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name        = "CodePipelineRole-${var.sys_name}-${var.aws_region}"
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

# IAM policy for CodePipeline
resource "aws_iam_policy" "codepipeline_policy" {
  name        = "CodePipelinePolicy-${var.sys_name}-${var.aws_region}"
  description = "IAM policy for CodePipeline"

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
          module.codepipeline_bucket.bucket.arn,
          "${module.codepipeline_bucket.bucket.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })
}

# Attach IAM policy to CodePipeline role
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# CodePipeline
resource "aws_codepipeline" "codepipeline" {
  name     = "codepipeline-${var.sys_name}-${var.aws_region}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = module.codepipeline_bucket.bucket.bucket
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
        RepositoryName = "my-repo"
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
        ProjectName = "my-project"
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
      input_artifacts  = ["build"]

      configuration = {
        ActionMode     = "CREATE_UPDATE"
        Capabilities   = "CAPABILITY_IAM,CAPABILITY_AUTO_EXPAND"
        OutputFileName = "CreateStackOutput.json"
        RoleArn        = aws_iam_role.codepipeline_role.arn
        StackName      = "my-stack"
        TemplatePath   = "build::template.yaml"
      }
    }
  }
}