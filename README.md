AWS Security Group in VPC with good maintenance of Security Group Rules
==============================================================================

# Features and highlights

A simple AWS Security Group terraform module with,

1. Easy to create/manage(existed) AWS security group
2. Port service to define security group rule easy, reference to a3linux/portservicemapping/null
3. IP whitelist module integrated, reference to a3linux/ipwhitelist/null
4. Default egress rules
5. Multiple sources, security group(group-name or group-id), IPs and whitelist groups(from whitelist module)

# About portservicemapping module for security group rule management

To optimize the service management between AWS resources, the port service mapping is an named and self explanation network service description.

For example, the stocked one in the port service mapping module is 

```
redis = [6379, 6379, "tcp", "Redis"]
```

and an additional port service mapping by the module itself,

```
my_port_service_mapping =  {
    service_a = [30000, 30000, "tcp", "Service A TCP port 30000"]
}
```

The key service_a can be used in the security group creation code as following, 

```hcl

variable "srv_port_service_mapping" {
    source = a3linux/portservicemapping/null

    service_a = [30000, 30000, "tcp", "Service A TCP port 30000"]
}

module "sg_a" {
    source = a3linux/security-group/aws

    ...
    port_service_mappings = var.srv_port_service_mapping
    allowed_services = ["service_a"]
    ...
}

```

# About the IP whitelist module

With the **a3linux/ipwhitelist/null** module, the source services can be added easy to security group as sources. There should be a separate module created and maintenance the IP whitelist based on **a3linux/ipwhitelist/null**, the instance of that module can work with this security group.

The variable _allowed_sources_ can be used to introduce the sources from this IP whitelist module instead of list many IPs there. This module will translate the valid sources to IPs and add to the security group.

A whitelist yml file should be provided as var.whitelist_file.

Please check the basic sample in **./examples/new_security_group**.

More samples TBD.
