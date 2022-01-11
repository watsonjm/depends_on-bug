variable "region" {
  type    = string
  default = "us-east-1"
}
variable "environment" {
  type    = string
  default = "test"
}
variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Map of generic tags to assign to all possible resources."
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "subnets" {
  type = map(
    object({
      cidr    = list(string)
      rt      = string
      name    = string
      auto_ip = bool #this can be optional possibly in the future.
    })
  )
  default = {
    public = {
      cidr    = ["10.0.0.0/16"]
      rt      = "public"
      name    = "public-subnet"
      auto_ip = true
    }
  }
}
variable "eks_cluster_version" {
  type        = string
  default     = "1.21"
  description = "The major and minor version of your EKS cluster."
}
variable "eks_min_on_demand_instances" {
  type    = number
  default = 1
}
variable "eks_max_on_demand_instances" {
  type    = number
  default = 10
}
variable "eks_on_demand_size" {
  type    = string
  default = "m4.large"
}
variable "eks_spot_sizes" {
  type    = list(string)
  default = ["m4.large"]
}