environment = "test"

common_tags = { #environment tag automatically added, add programmatic tags in local.common_tags.
  repo    = "github/depends_on-bug"
  managed = "terraform"
}

#VPC subnet
vpc_cidr = "10.0.0.0/16"
subnets = {
  public = {
    cidr    = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    rt      = "public"
    name    = "public-subnet"
    auto_ip = false
  }
  private = {
    cidr    = ["10.0.8.0/21", "10.0.16.0/21", "10.0.24.0/21"]
    rt      = "private"
    name    = "private-subnet"
    auto_ip = null
  }
  eks_public = {
    cidr    = ["10.0.160.0/19", "10.0.192.0/19", "10.0.224.0/19"]
    rt      = "public"
    name    = "eks-public-subnet"
    auto_ip = true
  }
}