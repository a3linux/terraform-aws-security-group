module "vpc" {
  count    = var.vpc_name == null ? 0 : 1
  source   = "a3linux/tagged-vpc/aws"

  vpc_name = var.vpc_name
  tags     = var.vpc_tags
}

module "port_service" {
  source = "a3linux/portservicemapping/null"

  port_service_mappings = var.port_service_mappings
}

module "whitelist" {
  count = var.whitelist_file == null ? 0 : 1

  source = "a3linux/ipwhitelist/null"

  whitelist_file = var.whitelist_file
  source_services = var.allowed_sources
  env     = module.context.env
}

module "eg_port_service" {
  source = "a3linux/portservicemapping/null"

  port_service_mappings = var.eg_port_service_mappings
}

module "eg_whitelist" {
  count = var.whitelist_file == null ? 0 : 1

  source = "a3linux/ipwhitelist/null"

  whitelist_file = var.whitelist_file
  source_services = var.eg_allowed_sources
  env     = module.context.env
}

data "aws_security_groups" "named_security_groups" {
  count = length(var.security_group_names) > 0 ? 1 : 0

  filter {
    name   = "group-name"
    values = var.security_group_names
  }

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

data "aws_security_groups" "eg_named_security_groups" {
  count = length(var.eg_security_group_names) > 0 ? 1 : 0

  filter {
    name   = "group-name"
    values = var.eg_security_group_names
  }

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

locals {
  sg_existing                   = var.is_external == true
  id                            = var.is_external ? join("", data.aws_security_group.existing.*.id) : join("", aws_security_group.default.*.id)
  arn                           = var.is_external ? join("", data.aws_security_group.existing.*.arn) : join("", aws_security_group.default.*.arn)
  egress_rule                   = var.egress_rule == true
  generated_name                = format("%s-sg", substr(md5(uuid()), 0, 8))
  failover_name                 = module.context.id == "" ? local.generated_name : module.context.id
  name                          = var.name != null ? var.name : local.failover_name
  tags                          = module.context.tags
  vpc_id                        = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id
  enable_cidr_rules             = length(var.allowed_ips) + length(var.allowed_sources) > 0
  enable_self_rules             = var.enable_self && length(var.allowed_services) > 0
  enable_cidr_rules_ipv6        = length(var.allowed_ipv6) > 0
  security_groups               = length(var.security_group_names) > 0 ? concat(var.security_groups, data.aws_security_groups.named_security_groups[0].ids) : var.security_groups
  enable_source_sec_group_rules = length(local.security_groups) == 0 ? false : true
  enable_source_prefix_list_ids = length(var.prefix_list_ids) == 0 ? false : true
  eg_security_groups            = length(var.eg_security_group_names) > 0 ? concat(var.eg_security_groups, data.aws_security_groups.eg_named_security_groups[0].ids) : var.eg_security_groups
  #egress local parameters
  enable_source_sec_group_rules_eg  = length(local.eg_security_groups) == 0 && length(var.eg_security_group_names) == 0 ? false : true
  enable_source_prefix_list_ids_eg  = length(var.eg_prefix_list_ids) == 0 ? false : true
  enable_cidr_rules_ipv6_eg         = length(var.eg_allowed_ipv6) > 0

  allowed_ips                       = var.whitelist_file == null ? var.allowed_ips : concat(module.whitelist[0].cidr_blocks, var.allowed_ips)
  allowed_services                  = [for s in var.allowed_services : lookup(module.port_service.port_service_mappings, s)]

  eg_allowed_ips                    = var.whitelist_file == null ? var.eg_allowed_ips : concat(module.eg_whitelist[0].cidr_blocks, var.eg_allowed_ips)
  eg_allowed_services               = [for s in var.eg_allowed_services : lookup(module.eg_port_service.port_service_mappings, s)]

  ports_source_sec_group_product    = setproduct(local.allowed_services, length(local.security_groups) > 0 ? local.security_groups : [""])
  ports_source_prefix_product       = setproduct(local.allowed_services, length(var.prefix_list_ids) > 0 ? var.prefix_list_ids : [""])

  ports_source_sec_group_product_eg = setproduct(local.eg_allowed_services, length(local.eg_security_groups) > 0 ? local.eg_security_groups : [""])
  ports_source_prefix_product_eg    = setproduct(local.eg_allowed_services, length(var.eg_prefix_list_ids) > 0 ? var.eg_prefix_list_ids : [""])
}

# security group
resource "aws_security_group" "default" {
  count = local.sg_existing ? 0 : 1

  name        = local.name
  vpc_id      = local.vpc_id
  description = var.description
  tags        = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Manage existed security group
data "aws_security_group" "existing" {
  count  = local.sg_existing ? 1 : 0
  id     = var.existing_sg_id
  vpc_id = local.vpc_id
}

#Module      : SECURITY GROUP RULE FOR EGRESS
#Description : Provides a security group rule resource. Represents a single egress
#              group rule, which can be added to external Security Groups.
resource "aws_security_group_rule" "egress" {
  count = (local.sg_existing == false && local.egress_rule == false) ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = local.id
}

resource "aws_security_group_rule" "egress_ipv6" {
  count = local.sg_existing == false && local.egress_rule == false ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = local.id
}

#Module      : SECURITY GROUP RULE FOR INGRESS
#Description : Provides a security group rule resource. Represents a single ingress
#              group rule, which can be added to external Security Groups.
resource "aws_security_group_rule" "ingress" {
  count = local.enable_cidr_rules == true ? length(local.allowed_services) : 0

  type              = "ingress"
  from_port         = element(local.allowed_services, count.index)[0]
  to_port           = element(local.allowed_services, count.index)[1]
  protocol          = element(local.allowed_services, count.index)[2]
  cidr_blocks       = local.allowed_ips
  security_group_id = local.id
}

resource "aws_security_group_rule" "ingress_self" {
  count = local.enable_self_rules == true ? length(local.allowed_services) : 0

  type              = "ingress"
  from_port         = element(local.allowed_services, count.index)[0]
  to_port           = element(local.allowed_services, count.index)[1]
  protocol          = element(local.allowed_services, count.index)[2]
  security_group_id = local.id
  self              = true
}

resource "aws_security_group_rule" "ingress_ipv6" {
  count = local.enable_cidr_rules_ipv6 == true ? length(local.allowed_services) : 0

  type              = "ingress"
  from_port         = element(local.allowed_services, count.index)[0]
  to_port           = element(local.allowed_services, count.index)[1]
  protocol          = element(local.allowed_services, count.index)[2]
  ipv6_cidr_blocks  = var.allowed_ipv6
  security_group_id = local.id
}

resource "aws_security_group_rule" "ingress_sg" {
  count = local.enable_source_sec_group_rules == true ? length(local.ports_source_sec_group_product) : 0

  type                     = "ingress"
  from_port                = element(element(element(local.ports_source_sec_group_product, count.index), 0), 0)
  to_port                  = element(element(element(local.ports_source_sec_group_product, count.index), 0), 1)
  protocol                 = element(element(element(local.ports_source_sec_group_product, count.index), 0), 2)
  source_security_group_id = local.enable_source_sec_group_rules == true ? element(element(local.ports_source_sec_group_product, count.index), 1) : 0
  security_group_id        = local.id
}

resource "aws_security_group_rule" "ingress_prefix" {
  count = local.enable_source_prefix_list_ids == true ? length(local.ports_source_prefix_product) : 0

  type              = "ingress"
  from_port         = element(element(local.ports_source_prefix_product, count.index), 0)[0]
  to_port           = element(element(local.ports_source_prefix_product, count.index), 0)[1]
  protocol          = element(element(local.ports_source_prefix_product, count.index), 0)[2]
  prefix_list_ids   = [element(element(local.ports_source_prefix_product, count.index), 1)]
  security_group_id = local.id
}

#egress rules configuration
resource "aws_security_group_rule" "egress_ipv4_rule" {
  count = local.egress_rule == true ? length(local.eg_allowed_services) : 0

  type              = "egress"
  from_port         = element(local.eg_allowed_services, count.index)[0]
  to_port           = element(local.eg_allowed_services, count.index)[1]
  protocol          = element(local.eg_allowed_services, count.index)[2]
  cidr_blocks       = local.eg_allowed_ips
  security_group_id = local.id
}

resource "aws_security_group_rule" "egress_ipv6_rule" {
  count = local.egress_rule == true && local.enable_cidr_rules_ipv6_eg == true ? length(local.eg_allowed_services) : 0

  type              = "egress"
  from_port         = element(local.eg_allowed_services, count.index)[0]
  to_port           = element(local.eg_allowed_services, count.index)[1]
  protocol          = element(local.eg_allowed_services, count.index)[2]
  ipv6_cidr_blocks  = var.eg_allowed_ipv6
  security_group_id = local.id
}

resource "aws_security_group_rule" "egress_sg_rule" {
  count = local.egress_rule == true && local.enable_source_sec_group_rules_eg == true ? length(local.ports_source_sec_group_product_eg) : 0

  type                     = "egress"
  from_port                = element(element(local.ports_source_sec_group_product_eg, count.index), 0)[0]
  to_port                  = element(element(local.ports_source_sec_group_product_eg, count.index), 0)[1]
  protocol                 = element(element(local.ports_source_sec_group_product_eg, count.index), 0)[2]
  source_security_group_id = element(element(local.ports_source_sec_group_product_eg, count.index), 1)
  security_group_id        = local.id
}

resource "aws_security_group_rule" "egress_prefix_rule" {
  count = local.egress_rule == true && local.enable_source_prefix_list_ids_eg == true ? length(local.ports_source_prefix_product_eg) : 0

  type              = "egress"
  from_port         = element(element(local.ports_source_prefix_product_eg, count.index), 0)[0]
  to_port           = element(element(local.ports_source_prefix_product_eg, count.index), 0)[1]
  protocol          = element(element(local.ports_source_prefix_product_eg, count.index), 0)[2]
  prefix_list_ids   = [element(element(local.ports_source_prefix_product_eg, count.index), 1)]
  security_group_id = local.id
}
