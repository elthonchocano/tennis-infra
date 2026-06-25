variable "bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
  default     = "tennis-league-frontend"
}