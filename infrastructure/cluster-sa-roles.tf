# ALB controller role
data "aws_iam_policy_document" "eks_oidc_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:sub"
      values = [
        "system:serviceaccount:aws-load-balancer-controller:aws-load-balancer-controller"
      ]
    }
    principals {
      identifiers = [
        local.eks_oidc_principal
      ]
      type = "Federated"
    }
  }
}


resource "aws_iam_policy" "alb_controller_policy" {
  name        = "alb-controller-policy"
  path        = "/"
  description = "alb controller policy"
  policy      = file("alb-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}

resource "aws_iam_role" "alb_controller_role" {
  name               = "${var.application_name}-${var.application_env}-aws-load-balancer-controller"
  description        = "IAM role for Kubernetes AWS Load Balancer controller."
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role.json
}

# External-dns role
resource "aws_iam_policy" "dns_controller_policy" {
  name        = "dns-controller-policy"
  path        = "/"
  description = "dns controller policy"
  policy = templatefile("${path.module}/dns-iam-policy.json", {
    zone_id = aws_route53_zone.dns.zone_id
  })
}

resource "aws_iam_role_policy_attachment" "dns_controller_policy" {
  policy_arn = aws_iam_policy.dns_controller_policy.arn
  role       = aws_iam_role.dns_controller_role.name
}

resource "aws_iam_role" "dns_controller_role" {
  name               = "${var.application_name}-${var.application_env}-dns-controller"
  description        = "IAM role for Kubernetes DNS controller."
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_dns.json
}

data "aws_iam_policy_document" "eks_oidc_assume_role_dns" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:sub"
      values = [
        "system:serviceaccount:external-dns:external-dns"
      ]
    }
    principals {
      identifiers = [
        local.eks_oidc_principal
      ]
      type = "Federated"
    }
  }
}

# cluster-autoscaler role
resource "aws_iam_policy" "ca_policy" {
  name        = "ca-policy"
  path        = "/"
  description = "CA controller policy"
  policy = templatefile("${path.module}/cluster-autoscaler-policy.json", {
    asg_resource = "arn:aws:autoscaling:${var.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/eks-worker_nodes*"
  })
}

resource "aws_iam_role_policy_attachment" "ca_policy" {
  policy_arn = aws_iam_policy.ca_policy.arn
  role       = aws_iam_role.ca_role.name
}

resource "aws_iam_role" "ca_role" {
  name               = "${var.application_name}-${var.application_env}-ca-role"
  description        = "IAM role for Kubernetes cluster-autoscaler controller."
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_ca.json
}

data "aws_iam_policy_document" "eks_oidc_assume_role_ca" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:sub"
      values = [
        "system:serviceaccount:cluster-autoscaler:cluster-autoscaler"
      ]
    }
    principals {
      identifiers = [
        local.eks_oidc_principal
      ]
      type = "Federated"
    }
  }
}