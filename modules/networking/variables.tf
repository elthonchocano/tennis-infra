variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC. Example: '10.0.0.0/16'"
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "lambda_sg_id" {
  description = "The ID of the security group attached to the Lambda"
  type        = string
}