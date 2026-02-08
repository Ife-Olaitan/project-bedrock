# General
variable "name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

# EKS
variable "cluster_version" {
  description = "EKS cluster Kubernetes version"
  type        = string
}

# S3
variable "student_id" {
  description = "Student ID for unique bucket naming"
  type        = string
}

variable "account_arn" {
  type = string
}

# RDS
variable "catalog_db_username" {
  description = "Username for catalog MySQL database"
  type        = string
}

variable "catalog_db_password" {
  description = "Password for catalog MySQL database"
  type        = string
  sensitive   = true
}

variable "orders_db_username" {
  description = "Username for orders PostgreSQL database"
  type        = string
}

variable "orders_db_password" {
  description = "Password for orders PostgreSQL database"
  type        = string
  sensitive   = true
}