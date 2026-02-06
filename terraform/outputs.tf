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

# Add this later when s3.tf is done
# output "assets_bucket_name" {
#   description = "S3 bucket for assets"
#   value       = aws_s3_bucket.assets.id
# }

#IAM
# output "dev_user_access_key_id" {
#   value = aws_iam_access_key.dev_view.id
# }
#
# output "dev_user_secret_access_key" {
#   value     = aws_iam_access_key.dev_view.secret
#   sensitive = true
# }