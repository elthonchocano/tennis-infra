# ==========================================
# 1. IDENTITY (AWS COGNITO + GOOGLE AUTH)
# ==========================================

module "identity" {
  source               = "./modules/identity"
  aws_region           = var.aws_region
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  frontend_domain      = module.frontend.cloudfront_domain_name
}

# ============================================
# 2. STATIC FRONTEND HOSTING (S3 + CLOUDFRONT)
# ============================================

module "frontend" {
  source      = "./modules/frontend"
  bucket_name = "tennis-league-frontend-prod"
}

# ============================================
# 3. CI/CD AUTOMATION (FRONTEND PIPELINE)
# ============================================

module "cicd" {
  source = "./modules/cicd"

  github_username     = var.github_username
  frontend_repo       = var.github_frontend_repo_name
  aws_region          = var.aws_region
  random_suffix       = module.frontend.random_suffix

  # Frontend specific links
  frontend_bucket_arn = module.frontend.bucket_arn
  frontend_bucket_id  = module.frontend.bucket_id
  cloudfront_id       = module.frontend.cloudfront_id
  
  # Auth configuration for frontend environment variables
  user_pool_client    = module.identity.user_pool_client_id
  user_pool_domain    = module.identity.user_pool_domain
  api_invoke_url      = var.backend_api
}

# ==========================================
# 4. MONITORING & ALERTS (CLOUDWATCH / SNS)
# ==========================================

module "monitoring" {
  source      = "./modules/monitoring"
  alert_email = var.alert_email
  cloudfront_id = module.frontend.cloudfront_id
}

# ==========================================
# 5. BUDGET ALERTS
# ==========================================

module "budget" {
  source             = "./modules/budget"
  budget_limit       = var.budget_limit_value
  notification_email = var.admin_email
}