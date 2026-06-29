variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem"
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code"
  type        = string
}

variable "runtime" {
  description = "The identifier of the function's runtime"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Lambda function's VPC configuration"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the Lambda function's VPC configuration"
  type        = list(string)
}

variable "db_host" {
  description = "The database host address"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "Database username for authentication"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password for authentication"
  type        = string
  sensitive   = true
}

variable "cognito_pool_id" {
  description = "The ID of the Cognito User Pool"
  type        = string
}

variable "cognito_client_id" {
  description = "The ID of the Cognito User Pool Client"
  type        = string
}

variable "frontend_url" {
  description = "The base URL of the frontend application (e.g., CloudFront distribution URL)"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}
