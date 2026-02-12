# Providers being used
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.99"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# AWS Provider - lets Terraform create AWS resources (VPC, EKS, RDS, S3, etc.)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "barakat-2025-capstone"
    }
  }
}