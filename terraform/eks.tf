# EKS Cluster: The Kubernetes control plane managed by AWS
resource "aws_eks_cluster" "main" {
  name     = "${var.name}-cluster"
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  # Network config: the cluster needs to know which subnets to use
  vpc_config {
    # Place the cluster endpoint in both public and private subnets
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )
  }

  # Enable API authentication mode for EKS Access Entries
  access_config {
    authentication_mode = "API"
  }

  # Control Plane Logging - sends logs to CloudWatch
  enabled_cluster_log_types = [
    "api",               # API server logs
    "audit",             # Audit logs (who did what)
    "authenticator",     # Authentication logs
    "controllerManager", # Controller manager logs
    "scheduler"          # Scheduler logs
  ]

  # Make sure the IAM role policies are attached before creating the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKS Managed Node Group: the EC2 instances where the pods will run
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  # Nodes go in private subnets (not directly accessible from internet)
  subnet_ids = aws_subnet.private[*].id

  # Instance configuration
  instance_types = ["t3.medium"]

  # Scaling: min, max, and desired number of nodes
  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  # Ensure IAM policies exist before creating nodes, and persist until nodes are deleted
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]
}

# IAM Role for the EKS Cluster (Control Plane) to manage AWS resources (networking, logging, etc.)
resource "aws_iam_role" "eks_cluster" {
  name = "${var.name}-cluster-role"

  # Allows the EKS service to use this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role for the Node Group (EC2 Instances - Worker Nodes) to allow them pull container images, communicate with the cluster, etc.
resource "aws_iam_role" "eks_nodes" {
  name = "${var.name}-node-role"

  # Allows EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Allows EKS to manage resources like ENIs, security groups, and logging
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Allows worker nodes to connect to the EKS cluster
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

# Allows the VPC CNI plugin to manage networking for pods
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

# Allows nodes to pull container images from ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}


# Grant cluster admin access to the current user
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.account_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.account_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}

# Get TLS certificate from EKS OIDC issuer URL (needed for thumbprint validation)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Register EKS OIDC provider with IAM (allows pods to assume IAM roles via service accounts)
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}