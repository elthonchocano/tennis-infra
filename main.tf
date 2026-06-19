# ==========================================
# 1. NETWORKING (VPC & SUBNETS)
# ==========================================

module "networking" {
  source   = "./modules/networking"
  vpc_cidr = "10.0.0.0/16"
  region = "us-east-1"
  lambda_sg_id = module.security.lambda_sg_id
}

# ==========================================
# 2. SECURITY GROUPS (FIREWALLS)
# ==========================================

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

# ==========================================
# 3. IDENTITY (AWS COGNITO + GOOGLE AUTH)
# ==========================================

resource "aws_cognito_user_pool" "pool" {
  name                     = "tennis-user-pool"
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name                = "phone_number"
    mutable             = true
    string_attribute_constraints {
      min_length = 7
      max_length = 15
    }
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_group" "admin_group" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "System Admin Group"
  precedence   = 1
}

resource "aws_cognito_user_group" "super_admin_group" {
  name         = "super-admin"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Super Admin Group with full system access"
  precedence   = 0
}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email profile openid"
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "tennis-frontend-client"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls                        = ["https://${module.frontend.cloudfront_domain_name}/"]
  logout_urls                          = ["https://${module.frontend.cloudfront_domain_name}/"]
  supported_identity_providers         = ["COGNITO", "Google"]

  depends_on = [aws_cognito_identity_provider.google]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "tennis-league-manager"
  user_pool_id = aws_cognito_user_pool.pool.id
}

# ===============================================
# 4. DATABASE (STANDARD RDS POSTGRES - FREE TIER)
# ===============================================

module "database" {
  source                = "./modules/database"
  db_subnet_ids         = module.networking.private_subnet_ids
  db_security_group_ids = [module.security.db_sg_id]
  db_username           = var.db_username
  db_password           = var.db_password
}

# ==========================================
# 5. COMPUTE (AWS LAMBDA + API GATEWAY)
# ==========================================

module "api_backend" {
  source             = "./modules/lambda_api"
  function_name      = "tennis-backend-api"
  filename           = "${path.root}/target/function.zip"
  handler            = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime            = "java21"
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.security.lambda_sg_id]
  db_host            = module.database.db_address
  db_name            = module.database.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  cognito_pool_id    = aws_cognito_user_pool.pool.id
  cognito_client_id  = aws_cognito_user_pool_client.client.id
  frontend_url       = "https://${module.frontend.cloudfront_domain_name}"
}

# ==========================================
# 6. STATIC FRONTEND HOSTING (S3 + CLOUDFRONT)
# ==========================================

module "frontend" {
  source = "./modules/frontend"
  bucket_name = "tennis-league-frontend-prod"
}

# ==========================================
# 7. CI/CD AUTOMATION (TWO SEPARATE PIPELINES)
# ==========================================

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
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
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
          module.frontend.bucket_arn,
          "${module.frontend.bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:UpdateFunctionCode", "lambda:GetFunction"]
        Resource = [module.api_backend.lambda_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = "*"
      },
      {
        Sid    = "CodeBuildVPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeDhcpOptions"
        ]
        Resource = "*"
      },
      {
        Sid      = "CodeBuildVPCENIPermissions"
        Effect   = "Allow"
        Action   = ["ec2:CreateNetworkInterfacePermission"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket        = "tennis-pipeline-artifacts-${module.frontend.random_suffix}"
  force_destroy = true
}

resource "aws_codestarconnections_connection" "github" {
  name          = "tennis-github-connection"
  provider_type = "GitHub"
}

# ------------------------------------------
# BACKEND PIPELINE CONFIGURATION
# ------------------------------------------

resource "aws_codebuild_project" "backend_build" {
  name          = "tennis-backend-build"
  service_role  = aws_iam_role.build_role.arn
  build_timeout = "15"

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = module.api_backend.lambda_name
    }

    environment_variable {
      name  = "DB_HOST"
      value = module.database.db_address
    }

    environment_variable {
      name  = "DB_NAME"
      value = module.database.db_name
    }

    environment_variable {
      name  = "DB_USERNAME"
      value = var.db_username
    }

    environment_variable {
      name  = "DB_PASSWORD"
      value = var.db_password
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  vpc_config {
    vpc_id             = module.networking.vpc_id
    subnets            = module.networking.private_subnet_ids
    security_group_ids = [module.security.lambda_sg_id]
  }
}

resource "aws_codepipeline" "backend_pipeline" {
  name     = "tennis-backend-pipeline"
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
      output_artifacts = ["backend_source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_username}/${var.github_backend_repo_name}"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "BuildAndDeployBackend"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["backend_source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.backend_build.name
      }
    }
  }
}

# ------------------------------------------
# FRONTEND PIPELINE CONFIGURATION
# ------------------------------------------

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
      value = module.api_backend.api_invoke_url
    }
    environment_variable {
      name  = "VITE_AUTH_CLIENT_ID"
      value = aws_cognito_user_pool_client.client.id
    }
    environment_variable {
      name  = "VITE_APP_VERSION"
      value = "v1.0.0"
    }
    environment_variable {
      name  = "FRONTEND_S3_BUCKET"
      value = module.frontend.bucket_id
    }
    environment_variable {
      name  = "CLOUDFRONT_DIST_ID"
      value = module.frontend.cloudfront_id
    }
    environment_variable {
      name  = "VITE_AUTH_STRATEGY"
      value = "cognito"
    }
    environment_variable {
      name  = "VITE_AUTH_SERVER_URL"
      value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

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
        FullRepositoryId = "${var.github_username}/${var.github_frontend_repo_name}"
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

      configuration = {
        ProjectName = aws_codebuild_project.frontend_build.name
      }
    }
  }
}

# ==========================================
# 8. MONITORING & ALERTS (CLOUDWATCH)
# ==========================================

resource "aws_sns_topic" "api_alerts" {
  name = "tennis-api-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.api_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "api_high_traffic" {
  alarm_name          = "tennis-api-high-traffic-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "5000"
  alarm_description   = "High traffic alarm on API Gateway"
  alarm_actions       = [aws_sns_topic.api_alerts.arn]

  dimensions = {
    ApiId = module.api_backend.api_id
  }
}
