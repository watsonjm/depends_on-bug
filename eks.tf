locals {
  eks_cluster_name    = var.environment == "test" ? "${local.name_tag}-eks-${random_string.random.result}" : "${local.name_tag}-eks"
  private_subnets_ids = module.subnets["private"].subnet_ids
  public_subnets_ids  = module.subnets["public"].subnet_ids
  common_tags = merge({
    environment = var.environment
    },
  var.common_tags)
  name_tag = "${var.environment}-eks"
  route_table = {
    public  = aws_route_table.public_default.id
    private = aws_route_table.private_default.id
  }
}

resource "random_string" "random" {
  keepers = {
    subnets = base64encode(join("", local.private_subnets_ids))
  }
  length  = 6
  special = false
}

resource "tls_private_key" "git_sync" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "eks" {
  #depends_on = [tls_private_key.git_sync]
  source     = "terraform-aws-modules/eks/aws"
  version    = "18.0.5"

  cluster_name                    = local.eks_cluster_name
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_service_ipv4_cidr       = "10.100.0.0/16"

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = local.private_subnets_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    disk_size      = 50
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {}
    spot = {
      desired_capacity         = var.eks_min_on_demand_instances
      max_capacity             = var.eks_max_on_demand_instances
      min_capacity             = var.eks_min_on_demand_instances
      instance_types           = var.eks_spot_sizes
      capacity_type            = "SPOT"
      key_name                 = "bastion-host"
      node_security_group_name = "spot_sg_name"
      create_launch_template   = true
      additional_tags = {
        ec2_type = "SPOT"
      }
      k8s_labels = {
        environment = "test"
        managed     = "terraform-shared"
        lifecycle   = "Ec2Spot"
      }
      taints = [
        {
          key    = "spotInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"
        }
      ]
    },
    demand = {
      desired_capacity         = var.eks_min_on_demand_instances
      max_capacity             = var.eks_max_on_demand_instances
      min_capacity             = var.eks_min_on_demand_instances
      instance_types           = [var.eks_on_demand_size]
      key_name                 = "bastion-host"
      node_security_group_name = "demand_sg_name"
      capacity_type            = "ON_DEMAND"
      create_launch_template   = true
      additional_tags = {
        ec2_type = "ON_DEMAND"
      }
      k8s_labels = {
        environment = var.environment
        managed     = "terraform-shared"
        lifecycle   = "OnDemand"
      }
    },
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      }
      tags = {
        ExtraTag = "example"
      }
    }
  }

  tags = {
    environment = "test"
    Terraform   = "true"
  }
}