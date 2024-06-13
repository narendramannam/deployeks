locals {
  name         = "${var.application_name}-${var.application_env}"
  cluster_name = "eks-${var.application_name}-${var.application_env}"
  vpc_name     = "vpc-${var.application_env}"
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    GithubOrg                = var.github_org
    GithubRepo               = var.github_project
    application_name         = var.application_name
    application_env          = var.application_env
    application_billing_code = var.application_billing_code
  }
  eks_oidc_issuer    = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
  eks_oidc_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer}"
}