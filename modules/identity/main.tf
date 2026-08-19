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
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls                        = ["https://${var.frontend_domain}/"]
  logout_urls                          = ["https://${var.frontend_domain}/"]
  supported_identity_providers         = ["COGNITO", "Google"]

  depends_on = [aws_cognito_identity_provider.google]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "tennis-league-manager"
  user_pool_id = aws_cognito_user_pool.pool.id
}