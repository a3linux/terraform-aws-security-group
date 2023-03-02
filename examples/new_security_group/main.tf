locals {
  context = {
    env = "dev"
    team = "om"
    service = "srv1"
    component = "com1"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}

module "new_sg_with_vpc_name" {
  source = "../../"

  vpc_name = "vpc-name"
  name     = "srv1-com1-1-sg"
  context  = local.context
  allowed_sources = ["srv2"]
  allowed_ips    = ["10.0.0.0/8"]
  allowed_services = ["ssh", "https"]
  whitelist_file = "../localwh.yml"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "sample-vpc"
  }
}

module "new_sg_with_vpc_id" {
  source = "../../"

  vpc_id    = aws_vpc.vpc.id
  name      = "srv1-com1-2-sg"
  context  = local.context
  allowed_sources = ["srv2"]
  allowed_ips = ["10.0.0.0/16"]
  allowed_services = ["ssh", "https"]
  enable_self = true
  whitelist_file = "../localwh.yml"
}

module "new_sg_with_sec_group_id" {
  source = "../../"

  vpc_id    = aws_vpc.vpc.id
  name      = "srv1-com1-3-sg"
  context  = local.context
  allowed_services = ["redis"]
  security_groups  = [ module.new_sg_with_vpc_id.id[0] ]
}
