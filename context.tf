# context module
module "context" {
  source          = "a3linux/context/null"

  context_values  = var.context
  additional_tags = try(var.tags, {})
}

variable "context" {
  type        = map(any)
  description = "Context init values, should be overrided always"
  default = {
    env       = "dev"
    region    = "us-west-2"
    team      = "tm1"
    service   = "srv1"
    component = "com1"
  }
}

variable "label_attributes" {
  type          = list(string)
  default       = ["team", "service", "component", "env", "region"]
  description   = "The attributes and order to generate the tags and context.id"
}

variable "label_delimiter" {
  type          = string
  default       = "-"
  description   = "Delimiter for label and id"
}

variable "tag_attributes" {
  type          = list(string)
  default       = ["team",  "service",  "component", "env"]
  description   = "Attributes for tags"
}

variable "tag_prefix" {
  type          = string
  default       = "con:"
}
