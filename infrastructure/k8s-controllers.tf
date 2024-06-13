# Helm release - ALB ingress controller
resource "kubernetes_namespace" "aws_load_balancer_controller" {
  metadata {
    name = "aws-load-balancer-controller"
  }
}

resource "helm_release" "alb-controller" {
  depends_on = [kubernetes_namespace.aws_load_balancer_controller, module.eks.eks_managed_node_groups]
  name       = "aws-load-balancer-controller"
  namespace  = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"

  values = [
    file("alb-controller-values.yaml")
  ]

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.name"
    value = "aws-load-balancer-controller"
    type  = "string"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller_role.arn
    type  = "string"
  }
}


# Helm release - external DNS controller
resource "kubernetes_namespace" "dns_controller" {
  metadata {
    name = "external-dns"
  }
}

resource "helm_release" "external-dns" {
  depends_on = [kubernetes_namespace.dns_controller, module.eks.eks_managed_node_groups]
  name       = "external-dns"
  namespace  = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.14.5"

  values = [
    file("alb-controller-values.yaml")
  ]

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
    type  = "string"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.dns_controller_role.arn
    type  = "string"
  }

  set {
    name  = "txtOwnerId"
    value = local.cluster_name
  }
}


# Helm release - cluster-autoscaler
resource "kubernetes_namespace" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }
}

resource "helm_release" "cluster-autoscaler" {
  depends_on = [kubernetes_namespace.cluster_autoscaler, module.eks.eks_managed_node_groups]
  name       = "cluster-autoscaler"
  namespace  = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.37.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = local.cluster_name
    type  = "string"
  }
  set {
    name  = "awsRegion"
    value = var.region
    type  = "string"
  }
  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
    type  = "string"
  }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ca_role.arn
    type  = "string"
  }
}

# Helm release - metric-server
resource "kubernetes_namespace" "metric_server" {
  metadata {
    name = "metric-server"
  }
}

resource "helm_release" "metric_server" {
  depends_on = [kubernetes_namespace.metric_server, module.eks.eks_managed_node_groups]
  name       = "metric-server"
  namespace  = "metric-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
}