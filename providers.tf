# Configure the Terraform engine and required providers
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider region
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "TLM - App"
      ManagedBy = "Terraform"
    }
  }
}