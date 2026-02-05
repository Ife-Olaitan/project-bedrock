terraform {
  backend "s3" {
    bucket       = "project-bedrock-state-buc"
    key          = "terraform.tfstate"
    region       = var.aws_region
    use_lockfile = true
  }
}
