# Required outputs
output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# S3 bucket for assets
output "assets_bucket_name" {
  description = "S3 bucket for assets"
  value       = aws_s3_bucket.assets.id
}

# IAM - Developer user credentials
output "dev_user_access_key_id" {
  description = "Access key ID for bedrock-dev-view user"
  value       = aws_iam_access_key.dev_view.id
}

output "dev_user_secret_access_key" {
  description = "Secret access key for bedrock-dev-view user"
  value       = aws_iam_access_key.dev_view.secret
  sensitive   = true
}

# RDS
output "catalog_mysql_endpoint" {
  description = "Catalog MySQL RDS endpoint"
  value       = aws_db_instance.catalog_mysql.endpoint
}

output "orders_postgres_endpoint" {
  description = "Orders PostgreSQL RDS endpoint"
  value       = aws_db_instance.orders_postgres.endpoint
}

# ESO (External Secrets Operator)
output "eso_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = aws_iam_role.eso.arn
}

# # ALB Controller
# output "alb_controller_role_arn" {
#   description = "IAM role ARN for AWS Load Balancer Controller"
#   value       = aws_iam_role.alb_controller.arn
# }
