data "aws_eks_cluster_auth" "default" {
  name = "tpr"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.app
  cluster_version = "1.28"

  cluster_endpoint_public_access = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.public_nets
  control_plane_subnet_ids = var.public_nets

  eks_managed_node_group_defaults = {
    ami_type       = "${var.ami_type}"
    instance_types = ["${var.instance_types}"]
  }

  eks_managed_node_groups = {
    node-group1 = {
      name = "${var.app}-node-group"

      min_size     = 2
      max_size     = 2
      desired_size = 2

    }
  }

  cluster_addons = {
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }
  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/${var.user1}"
      username = "${var.user1}"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/${var.user2}"
      username = "${var.user2}"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/${var.user3}"
      username = "${var.user3}"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/${var.user4}"
      username = "${var.user4}"
      groups   = ["system:masters"]
    },
  ]

  tags = {
    app       = "${var.app}"
    tf_module = "${var.app}-eks"
  }
}

resource "aws_autoscaling_attachment" "node_group_to_NLB_attachment" {
  autoscaling_group_name = module.eks.eks_managed_node_groups_autoscaling_group_names[0]
  lb_target_group_arn    = var.target_group_arn
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }

  depends_on = [module.eks]
}

resource "helm_release" "traefik_ingress" {
  name      = "traefik-ingress-controller"
  namespace = "traefik"

  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"

  values = [
    "${file("./eks/traefik_values.yaml")}"
  ]
  depends_on = [kubernetes_namespace.traefik]
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on = [module.eks]
}

resource "helm_release" "cert-manager" {
  name      = "cert-manager"
  namespace = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [kubernetes_namespace.cert-manager]
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
}

data "template_file" "cluster-issuer" {
  template = file("./eks/cluster-issuer.yaml")
  vars = {
    cluster_issuer_email = var.cluster_issuer_email
  }
}

resource "kubectl_manifest" "cluster-issuer" {
  yaml_body = tostring(data.template_file.cluster-issuer.rendered)

  depends_on = [helm_release.cert-manager]
}

resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
  depends_on = [module.eks]
}
