variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "google_client_id" {
  type        = string
  description = "Google OAuth Client ID for Cognito Federation"
}

variable "google_client_secret" {
  type        = string
  description = "Google OAuth Client Secret for Cognito Federation"
  sensitive   = true
}

variable "db_username" {
  type    = string
  default = "tennis_admin"
}

variable "db_password" {
  type        = string
  description = "Master password for Aurora Serverless v2 Postgres Cluster"
  sensitive   = true
}

variable "app_domain" {
  type        = string
  default     = "localhost:3000"
  description = "Primary frontend application domain used for CORS and auth redirects"
}

variable "github_username" {
  type        = string
  description = "The GitHub username or organization owner of the repositories"
}

variable "github_backend_repo_name" {
  type        = string
  default     = "tennis-backend"
  description = "The repository name for the Quarkus backend application"
}

variable "github_frontend_repo_name" {
  type        = string
  default     = "tennis-frontend"
  description = "The repository name for the React frontend application"
}

variable "alert_email" {
  description = "Email address to receive infrastructure alerts"
  type        = string
}
