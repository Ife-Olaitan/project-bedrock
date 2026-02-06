# CloudWatch Observability Add-on for container logs
# - Installs the CloudWatch agent as a DaemonSet on all nodes
# - Ships container logs to CloudWatch Logs
# - Lets you see retail-store-app logs in the CloudWatch console

# Ships pod logs from all nodes to CloudWatch Logs
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "amazon-cloudwatch-observability"

  depends_on = [aws_eks_node_group.main]
}

# IAM policy for CloudWatch agent on nodes
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
