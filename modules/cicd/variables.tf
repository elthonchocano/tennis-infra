variable "github_username" { type = string }
variable "backend_repo" { type = string }
variable "frontend_repo" { type = string }
variable "aws_region" { type = string }
variable "lambda_name" { type = string }
variable "lambda_arn" { type = string }
variable "db_address" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "api_invoke_url" { type = string }
variable "user_pool_client" { type = string }
variable "user_pool_domain" { type = string }
variable "frontend_bucket_arn" { type = string }
variable "frontend_bucket_id" { type = string }
variable "cloudfront_id" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "lambda_sg_id" { type = string }
variable "random_suffix" { type = string }
variable "codebuild_sg_id" {
  type = string
}
variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}
