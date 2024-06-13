module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.8.1"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]


  private_subnet_names = ["eks-nodes-1", "eks-nodes-2", "eks-nodes-3"]
  intra_subnet_names   = ["eks-cluster-1", "eks-cluster-2", "eks-cluster-3"]
  public_subnet_names  = ["eks-external-1", "eks-external-2", "eks-external-3"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
