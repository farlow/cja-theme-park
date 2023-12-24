# recupère dynamiquement les zones de disponibilités
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"

  name = "${var.app}-VPC"

  cidr                    = var.vpc_cidr
  azs                     = data.aws_availability_zones.available.names
  private_subnets         = var.private_subnets
  public_subnets          = var.public_subnets
  create_igw              = true
  enable_nat_gateway      = false
  map_public_ip_on_launch = true

  tags = {
    app       = "${var.app}"
    tf_module = "${var.app}-vpc"
  }
}

resource "aws_lb" "nlb" {
    name               = "${var.app}-NLB"
    internal           = false
    load_balancer_type = "network"
    security_groups    = ["${module.nlb_sg.security_group_id}"]
    subnets            = module.vpc.public_subnets

    enable_deletion_protection = false

    tags = {
      app         = "${var.app}"
    }
}

resource "aws_lb_listener" "app-nlb-listener" {
    load_balancer_arn = aws_lb.nlb.arn
    port              = 443
    protocol          = "TCP"

    default_action {
        type             = "forward"
        target_group_arn =  aws_lb_target_group.app-nlb-target-group.arn
    }
}

resource "aws_lb_target_group" "app-nlb-target-group" {
    name     = "${var.app}-NLB-TG"
    port     = 32443
    protocol = "TCP"
    vpc_id   = module.vpc.vpc_id

    health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        interval            = 30
        path                = "/actuator/health"
        matcher             = "200"
    }
}

module "nlb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"

  name        = "${var.app}-NLB-SG"
  description = "Security group for NLB"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
  tags = {
    app       = "${var.app}"
    tf_module = "${var.app}-NLB-SG"
  }
}
