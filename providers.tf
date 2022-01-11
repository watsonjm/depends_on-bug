terraform {
  required_version = "~> 1.1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.71.0"
    }
  }
}
provider "aws" {
  region = var.region
  default_tags { tags = local.common_tags }
}