resource "aws_iam_role" "pipeline_role" {
  name = "tennis-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "pipeline_policy" {
  name = "tennis-codepipeline-policy"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning",
          "s3:PutObjectAcl", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"
        ]
        Resource = [aws_s3_bucket.pipeline_bucket.arn, "${aws_s3_bucket.pipeline_bucket.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "build_role" {
  name = "tennis-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "build_policy" {
  name = "tennis-codebuild-policy"
  role = aws_iam_role.build_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.pipeline_bucket.arn,
          "${aws_s3_bucket.pipeline_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = [
          var.frontend_bucket_arn,
          "${var.frontend_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = "*"
      },
      {
        Sid      = "CodeBuildS3ArtifactAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.pipeline_bucket.arn}/builds/*"]
      }
    ]
  })
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket        = "tennis-pipeline-artifacts-${var.random_suffix}"
  force_destroy = true
}

resource "aws_codestarconnections_connection" "github" {
  name          = "tennis-github-connection"
  provider_type = "GitHub"
}

# --- Frontend Build ---
resource "aws_codebuild_project" "frontend_build" {
  name          = "tennis-frontend-build"
  service_role  = aws_iam_role.build_role.arn
  build_timeout = "15"

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "VITE_API_URL"
      value = var.api_invoke_url
    }
    environment_variable {
      name  = "VITE_AUTH_CLIENT_ID"
      value = var.user_pool_client
    }
    environment_variable {
      name  = "VITE_APP_VERSION"
      value = "v1.0.0"
    }
    environment_variable {
      name  = "FRONTEND_S3_BUCKET"
      value = var.frontend_bucket_id
    }
    environment_variable {
      name  = "CLOUDFRONT_DIST_ID"
      value = var.cloudfront_id
    }
    environment_variable {
      name  = "VITE_AUTH_STRATEGY"
      value = "cognito"
    }
    environment_variable {
      name  = "VITE_AUTH_SERVER_URL"
      value = "https://${var.user_pool_domain}.auth.${var.aws_region}.amazoncognito.com"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

# --- Pipeline ---
resource "aws_codepipeline" "frontend_pipeline" {
  name     = "tennis-frontend-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["frontend_source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_username}/${var.frontend_repo}"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "BuildAndDeployFrontend"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["frontend_source_output"]
      version         = "1"

      configuration = { ProjectName = aws_codebuild_project.frontend_build.name }
    }
  }
}