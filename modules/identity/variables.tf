variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "google_client_id" {
  description = "Google OAuth Client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
  sensitive   = true
}

variable "frontend_domain" {
  description = "The CloudFront domain name to be used in callback/logout URLs"
  type        = string
}
