resource "aws_iam_service_linked_role" "aws_service_role" {
  aws_service_name = "autoscaling.amazonaws.com"
}

# Encryption keys
module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  description = "Customer managed key to encrypt EKS managed node group volumes"
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]

  key_service_roles_for_autoscaling = [
    aws_iam_service_linked_role.aws_service_role.arn,
    module.eks.cluster_iam_role_arn,
  ]

  aliases = ["eks/${local.name}/ebs"]

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.13"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_version

  cluster_endpoint_public_access            = true
  cluster_endpoint_private_access           = true
  enable_irsa                               = true
  create_kms_key                            = true
  enable_kms_key_rotation                   = true
  kms_key_aliases                           = ["eks/${local.name}/controlplane"]
  attach_cluster_encryption_policy          = true
  cluster_encryption_policy_use_name_prefix = false
  cluster_encryption_policy_name            = "eks-kms-${local.name}-policy"
  cluster_encryption_policy_description     = "cluster encryption key policy"
  cluster_enabled_log_types = [
    "audit",
    "api",
    "authenticator"
  ]

  cluster_encryption_config = {
    "resources" : [
      "secrets"
    ]
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    # Custom AMI, using module provided bootstrap data
    worker_nodes = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      # Current bottlerocket AMI
      ami_id   = data.aws_ami.eks_default_bottlerocket.image_id
      ami_type = "BOTTLEROCKET_x86_64"

      # Use module user data template to bootstrap
      enable_bootstrap_user_data = true
      # This will get added to the template
      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = true

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"
        # 
      EOT
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }
      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group role"
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        # additional                         = aws_iam_policy.node_additional.arn
      }

      launch_template_tags = {
        # enable discovery of autoscaling groups by cluster-autoscaler
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${local.name}" : "owned",
      }
    }
  }
  enable_cluster_creator_admin_permissions = true

  access_entries = {}

  tags = local.tags
}