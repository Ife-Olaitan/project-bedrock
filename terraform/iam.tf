# Create the developer user (IAM user for developer access - read only)
resource "aws_iam_user" "dev_view" {
  name = "bedrock-dev-view"
}

# Attach AWS ReadOnlyAccess policy for console access - allows viewing EC2, EKS, CloudWatch, etc. but not modifying
resource "aws_iam_user_policy_attachment" "dev_view_readonly" {
  user       = aws_iam_user.dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Generate access keys for CLI access
resource "aws_iam_access_key" "dev_view" {
  user = aws_iam_user.dev_view.name
}

# Allow dev user to upload to assets bucket (for testing Lambda trigger)
resource "aws_iam_user_policy" "dev_view_s3_upload" {
  name = "assets-bucket-upload"
  user = aws_iam_user.dev_view.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}

# Create an access entry to allow "developer user" to access the EKS cluster
resource "aws_eks_access_entry" "dev_view" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_user.dev_view.arn
  type          = "STANDARD"
}

# Grant the "view" policy to "developer user"  - read-only access to cluster resources
resource "aws_eks_access_policy_association" "dev_view" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_user.dev_view.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.dev_view]
}