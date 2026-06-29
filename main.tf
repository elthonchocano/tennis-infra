# ==========================================
# 1. NETWORKING (VPC & SUBNETS)
# ==========================================

module "networking" {
  source       = "./modules/networking"
  vpc_cidr     = "10.0.0.0/16"
  region       = var.aws_region
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

module "identity" {
  source               = "./modules/identity"
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  frontend_domain      = module.frontend.cloudfront_domain_name
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
  region             = var.aws_region
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
  cognito_pool_id    = module.identity.user_pool_id
  cognito_client_id  = module.identity.user_pool_client_id
  frontend_url       = "https://${module.frontend.cloudfront_domain_name}"
}

# ============================================
# 6. STATIC FRONTEND HOSTING (S3 + CLOUDFRONT)
# ============================================

module "frontend" {
  source      = "./modules/frontend"
  bucket_name = "tennis-league-frontend-prod"
}

# ============================================
# 7. CI/CD AUTOMATION (TWO SEPARATE PIPELINES)
# ============================================

module "cicd" {
  source = "./modules/cicd"

  github_username = var.github_username
  backend_repo    = var.github_backend_repo_name
  frontend_repo   = var.github_frontend_repo_name
  aws_region      = var.aws_region
  random_suffix   = module.frontend.random_suffix

  # Backend
  lambda_name    = module.api_backend.lambda_name
  lambda_arn     = module.api_backend.lambda_arn
  api_invoke_url = module.api_backend.api_invoke_url

  # Database
  db_address  = module.database.db_address
  db_name     = module.database.db_name
  db_username = var.db_username
  db_password = var.db_password

  # Cognito
  user_pool_client = module.identity.user_pool_client_id
  user_pool_domain = module.identity.user_pool_domain

  # Frontend
  frontend_bucket_arn = module.frontend.bucket_arn
  frontend_bucket_id  = module.frontend.bucket_id
  cloudfront_id       = module.frontend.cloudfront_id

  # Networking
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  lambda_sg_id       = module.security.lambda_sg_id
}

# ==========================================
# 8. MONITORING & ALERTS (CLOUDWATCH)
# ==========================================

module "monitoring" {
  source      = "./modules/monitoring"
  alert_email = var.alert_email
  api_id      = module.api_backend.api_id
}

# ==========================================
# 9. BUDGET ALERTS
# ==========================================
module "budget" {
  source             = "./modules/budget"
  budget_limit       = var.budget_limit_value
  notification_email = var.admin_email
}
