# module vpc
variable "vpc_name" {
  description = "Fetch VPC by name tag, if vpc_id is present, ignore this"
  type        = string
  default     = null
}

variable "vpc_tags" {
  description = "VPC tags to pick up VPC"
  type        = map(any)
  default     = {}
}

variable "vpc_id" {
  description = "VPC id, if this is provided, the vpc_name will be ignored"
  type        = string
  default     = null
}

# Security Group to create
variable "name" {
  description = "Secruity group name, if not present will auto generated based on context"
  type        = string
  default     = null
}

variable "description" {
  description = "description"
  type        = string
  default     = "Security Group managed by IaC terraform"
}

variable "tags" {
  description = "Custom tags"
  type        = map(any)
  default     = {}
}

variable "whitelist_file" {
  description = "IP Whitelist file for a3linux/ipwhitelist/null module"
  type        = string
  default     = null
}

# For ingress rules
# For module whitelist(ingress)
variable "allowed_services" {
  description = "Allowed services, the key in port service mapping module or port_service_mappings"
  type        = list(string)
  default     = []
}

variable "allowed_sources" {
  description = "List of allowed sources defined for whitelist module to generate IP list"
  type        = list(any)
  default     = []
}

variable "allowed_ips" {
  description = "List of allowed ip, additional IP list to sources list"
  type        = list(string)
  default     = []
}

# module port_service
variable "port_service_mappings" {
  description = "Customized port service mappings, {service-name = [from_port, to_port, protocol, descrtiption]} which will merge to port service mapping module one"
  type        = map(list(any))
  default     = {}
}

variable "security_groups" {
  description = "List of Security Group IDs(group-id) allowed to connect to the instance."
  type        = list(string)
  default     = []
}

variable "security_group_names" {
  description = "List of Security Group Names(group-name) allowed to connect to the instance."
  type        = list(string)
  default     = []
}

variable "allowed_ipv6" {
  description = "List of allowed ipv6."
  type        = list(any)
  default     = []
}

# Security group to update
variable "is_external" {
  description = "Enable to update and manage existed security Group, the module will NOT create security group"
  type        = bool
  default     = false
}

variable "existing_sg_id" {
  description = "Provide existing security group id"
  type        = string
  default     = null
}

variable "prefix_list_ids" {
  description = "Provide allow source Prefix id of resources"
  type        = list(string)
  default     = []
}

##########################33
# egress Rules parameters
variable "egress_rule" {
  description = "Enable to create egress rule, if it is false, only default security group egress rule created to allow to access all"
  type        = bool
  default     = false
}

# For module whitelist(egress)
variable "eg_allowed_sources" {
  description = "List of allowed sources defined for whitelist module to generate IP list"
  type        = list(any)
  default     = []
}

variable "eg_allowed_ips" {
  description = "List of allowed ip, additional IP list to sources list"
  type        = list(string)
  default     = []
}

variable "enable_self" {
  description = "Allow ingress traffic for the security group internal(self)"
  type        = bool
  default     = false
}

# module port_service
variable "eg_port_service_mappings" {
  description = "Customized port service mappings, {service-name = [from_port, to_port, protocol, descrtiption]}"
  type        = map(list(any))
  default     = {}
}

variable "eg_allowed_services" {
  description = "Allowed services, the key in port_service module or port_service_mappings"
  type        = list(string)
  default     = []
}

variable "eg_security_groups" {
  description = "List of Security Group IDs allowed to connect to the instance."
  type        = list(string)
  default     = []
}

variable "eg_security_group_names" {
  description = "List of Egress Security Group Names(group-name) allowed to connect to the instance."
  type        = list(string)
  default     = []
}

variable "eg_allowed_ipv6" {
  description = "List of allowed ipv6."
  type        = list(any)
  default     = []
}

variable "eg_prefix_list_ids" {
  description = "List of prefix list IDs (for allowing access to VPC endpoints)Only valid with egress"
  type        = list(any)
  default     = []
}
