# TODO: ASG Scaling Policy 정해야함

terraform {
  required_version = ">= 0.12"
}

# aws 관련 기능을 가지고 있는 모듈
provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  exclude_names = []
}
