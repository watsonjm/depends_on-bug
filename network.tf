###########################
# VPC
###########################
module "vpc" {
  source               = "github.com/watsonjm/tf-aws-vpc?ref=v1.0.2"
  name                 = "${local.name_tag}-main-vpc"
  tag_prefix           = local.name_tag
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_classiclink   = false
  flow_logs            = true
}

###########################
# ROUTING
###########################
resource "aws_eip" "ngw" {
  vpc = true

  tags = { Name = "${local.name_tag}-ngw" }
}

resource "aws_nat_gateway" "default" {
  subnet_id     = local.public_subnets_ids.0
  allocation_id = aws_eip.ngw.id

  tags = { Name = "${local.name_tag}-ngw" }
}

resource "aws_internet_gateway" "default" {
  vpc_id = module.vpc.vpc_id

  tags = { Name = "${local.name_tag}-default-igw" }
}

resource "aws_route_table" "public_default" {
  vpc_id = module.vpc.vpc_id

  tags = { Name = "${local.name_tag}-public-rt" }
}

resource "aws_route" "public_default" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_default.id
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route_table" "private_default" {
  vpc_id = module.vpc.vpc_id

  tags = { Name = "${local.name_tag}-private-rt" }
}

resource "aws_route" "private_default" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_default.id
  nat_gateway_id         = aws_nat_gateway.default.id
}

###########################
# SUBNETS
###########################
module "subnets" {
  for_each                = var.subnets
  source                  = "github.com/watsonjm/tf-aws-subnet?ref=v1.0.3"
  name                    = "${local.name_tag}-${each.value.name}"
  vpc_id                  = module.vpc.vpc_id
  cidr                    = each.value.cidr
  az_ids                  = data.aws_availability_zones.all.zone_ids
  rt_id                   = lookup(local.route_table, each.value.rt, try(aws_route_table.private_default.id, null))
  map_public_ip_on_launch = each.value.auto_ip
}