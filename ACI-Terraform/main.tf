terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

# Configure the provider with your Cisco APIC credentials.
provider "aci" {
  # APIC Username
  username = var.user.username
  # APIC Password
  password = var.user.password
  # APIC URL
  url      = var.user.url
  insecure = true
}

resource "aci_tenant" "terraform_tenant" {
    name        =  var.tenant
    description = "This tenant is created by terraform"
}

# Define an ACI Tenant VRF Resource.
resource "aci_vrf" "terraform_vrf" {
    tenant_dn   = aci_tenant.terraform_tenant.id
    description = "VRF Created Using Terraform"
    name        = var.vrf
}

# Define an ACI Tenant BD Resource1
resource "aci_bridge_domain" "terraform_bd1" {
    tenant_dn          = aci_tenant.terraform_tenant.id
    relation_fv_rs_ctx = aci_vrf.terraform_vrf.id
    description        = "BD Created Using Terraform"
    name               = var.bd1
}


# Define an ACI Tenant BD Subnet Resource1.
resource "aci_subnet" "terraform_bd_subnet1" {
    parent_dn   = aci_bridge_domain.terraform_bd1.id
    description = "Subnet Created Using Terraform"
    ip          = var.subnet1
    scope       = ["public"]
}

# Define an ACI Tenant BD Resource2
resource "aci_bridge_domain" "terraform_bd2" {
    tenant_dn          = aci_tenant.terraform_tenant.id
    relation_fv_rs_ctx = aci_vrf.terraform_vrf.id
    description        = "BD Created Using Terraform"
    name               = var.bd2
}


# Define an ACI Tenant BD Subnet Resource2.
resource "aci_subnet" "terraform_bd_subnet2" {
    parent_dn   = aci_bridge_domain.terraform_bd2.id
    description = "Subnet Created Using Terraform"
    ip          = var.subnet2
    scope       = ["public"]
}

# Define an ACI filter Resource.
resource "aci_filter" "terraform_filter" {
    for_each    = var.filters
    tenant_dn   = aci_tenant.terraform_tenant.id
    description = "This is filter ${each.key} created by terraform"
    name        = each.value.filter
}

# Define an ACI filter entry resource.
resource "aci_filter_entry" "terraform_filter_entry" {
    for_each      = var.filters
    filter_dn     = aci_filter.terraform_filter[each.key].id
    name          = each.value.entry
    ether_t       = "ipv4"
    prot          = each.value.protocol
    d_from_port   = each.value.port
    d_to_port     = each.value.port
}

# Define an ACI Contract Resource.
resource "aci_contract" "terraform_contract" {
    for_each      = var.contracts
    tenant_dn     = aci_tenant.terraform_tenant.id
    name          = each.value.contract
    description   = "Contract created using Terraform"
    scope         = "context"
}

# Define an ACI Contract Subject Resource.
resource "aci_contract_subject" "terraform_contract_subject" {
    for_each                      = var.contracts
    contract_dn                   = aci_contract.terraform_contract[each.key].id
    name                          = each.value.subject
    relation_vz_rs_subj_filt_att  = [aci_filter.terraform_filter[each.value.filter].id]
}

# Define an ACI Application Profile Resource.
resource "aci_application_profile" "terraform_ap" {
    tenant_dn  = aci_tenant.terraform_tenant.id
    name       = var.ap
    description = "App Profile Created Using Terraform"
}

resource "aci_application_epg" "terraform_epg" {
    for_each                = var.epgs
    application_profile_dn  = aci_application_profile.terraform_ap.id
    name                    = each.value.epg
    relation_fv_rs_bd       = aci_bridge_domain.terraform_bd1.id
    description             = "EPG Created Using Terraform"
}

# Associate the EPGs with the contracts
resource "aci_epg_to_contract" "terraform_epg_contract" {
    for_each           = var.epg_contracts
    application_epg_dn = aci_application_epg.terraform_epg[each.value.epg].id
    contract_dn        = aci_contract.terraform_contract[each.value.contract].id
    contract_type      = each.value.contract_type
}

resource "aci_vlan_pool" "example" {
  name  = var.vlan_pool
  description = "ESX VLAN Pool"
  alloc_mode  = "dynamic"
}

resource "aci_ranges" "range_1" {
  vlan_pool_dn  = aci_vlan_pool.example.id
  description   = "ESX VLAN Pool Range"
  from          = "vlan-1000"
  to            = "vlan-1500"
  alloc_mode    = "inherit"
}

resource "aci_vmm_domain" "vmm_domain" {
    provider_profile_dn = "uni/vmmp-VMware"
    name                = var.vmm_domain
    enable_tag          = "yes"
}

resource "aci_vmm_controller" "vc1" {
  vmm_domain_dn                   = aci_vmm_domain.vmm_domain.id
  name                            = "vc1"
  host_or_ip                      = "198.18.133.30"
  root_cont_name                  = "dCloud-DC"
  relation_vmm_rs_vxlan_ns_def    = aci_vlan_pool.example.id
}

resource "aci_vmm_credential" "example" {
  vmm_domain_dn  = aci_vmm_domain.vmm_domain.id
  name  = "vmm_credential_1"
  pwd = "C1sco12345"
  usr = "administrator@vsphere.local"
}

resource "aci_attachable_access_entity_profile" "pseudoco_ent_prof" {
  description = "AAEP description"
  name        = "pseudoco_ent_prof"
}

resource "aci_aaep_to_domain" "pseudoco_aaep_to_domain" {
  attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.pseudoco_ent_prof.id
  domain_dn                           = aci_vmm_domain.vmm_domain.id
}

resource "aci_lldp_interface_policy" "example_lldp" {
  name        = "demo_lldp_pol"
  admin_rx_st = "enabled"
  admin_tx_st = "enabled"
} 

resource "aci_cdp_interface_policy" "example_cdp" {
  name        = "demo_cdp_pol"
  admin_st    = "enabled"
}

resource "aci_lacp_policy" "example_lacp" {
  name        = "demo_lacp_pol"
  mode        = "mac-pin-nicload"
}

resource "aci_fabric_if_pol" "example_if_policy" {
  name        = "fabric_if_pol_1"
  auto_neg    = "on"
  speed       = "10G"
}

resource "aci_vswitch_policy" "example_vmm_policy" {
  vmm_domain_dn  = aci_vmm_domain.vmm_domain.id
  relation_vmm_rs_vswitch_override_lldp_if_pol = aci_lldp_interface_policy.example_lldp.id
  relation_vmm_rs_vswitch_override_lacp_pol = aci_lacp_policy.example_lacp.id
}

resource "aci_leaf_interface_profile" "example_interface_profile" {
    name        = "pseudoco_interface_profile"
}

resource "aci_leaf_access_port_policy_group" "example_access_port_policy_group" {
    name        = "pseudoco_access_port"
    relation_infra_rs_att_ent_p = aci_attachable_access_entity_profile.pseudoco_ent_prof.id
    relation_infra_rs_cdp_if_pol = aci_cdp_interface_policy.example_cdp.id
    relation_infra_rs_h_if_pol = aci_fabric_if_pol.example_if_policy.id
} 

resource "aci_access_port_selector" "example_port_selector" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.example_interface_profile.id
    name                      = "pseudoco_port_selector"
    access_port_selector_type = "ALL"
}

resource "aci_access_port_block" "test_port_block" {
  access_port_selector_dn           = aci_access_port_selector.example_port_selector.id
  name                              = "pseudoco_test_block"
  from_card                         = "1"
  from_port                         = "4"
  to_card                           = "1"
  to_port                           = "5"
}

resource "aci_leaf_profile" "example_leaf_profile" {
  name        = "leaf"
  leaf_selector {
    name                    = "one"
    switch_association_type = "range"
    node_block {
      name  = "blk1"
      from_ = "101"
      to_   = "102"
    }
  }
}

resource "aci_leaf_selector" "example_leaf_selector" {
  leaf_profile_dn         = aci_leaf_profile.example_leaf_profile.id
  name                    = "pseudoco_leaf_selector"
  switch_association_type = "range"
}

resource "aci_node_block" "check" {
  switch_association_dn   = aci_leaf_selector.example_leaf_selector.id
  name                    = "pseudoco_block"
  from_                   = "101"
  to_                     = "102"
}