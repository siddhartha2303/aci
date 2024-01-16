variable "user" {
  description = "Login information"
  type        = map
  default     = {
    username = "admin"
    password = "C1sco12345"
    url      = "https://10.10.20.14"
  }
}

variable "tenant" {
    type    = string
    default = "Pseudoco"
}

variable "vrf" {
        type    = string
        default = "Pseudoco_vrf-01"
    }

variable "bd1" {
    type    = string
    default = "192.168.30.0_24"
}

variable "subnet1" {
    type    = string
    default = "192.168.30.1/24"
}

variable "bd2" {
    type    = string
    default = "192.168.31.0_24"
}

variable "subnet2" {
    type    = string
    default = "192.168.31.1/24"
}

variable "filters" {
   description = "Create filters with these names and ports"
   type        = map
   default     = {
     filter_https = {
       filter   = "https",
       entry    = "https",
       protocol = "tcp",
       port     = "443"
     },
     filter_sql = {
       filter   = "sql",
       entry    = "sql",
       protocol = "tcp",
       port     = "1433"
     }
   }
 }

variable "contracts" {
   description = "Create contracts with these filters"
   type        = map
   default     = {
     contract_web = {
       contract = "web",
       subject  = "https",
       filter   = "filter_https"
     },
     contract_sql = {
       contract = "sql",
       subject  = "sql",
       filter   = "filter_sql"
     }
   }
 }

variable "ap" {
    description = "Create application profile"
    type        = string
    default     = "finance"
}
 
variable "epgs" {
    description = "Create epg"
    type        = map
    default     = {
        web_epg = {
            epg   = "web",
            bd    = "prod_bd",
            encap = "21"
        },
        db_epg = {
            epg   = "db",
            bd    = "prod_bd",
            encap = "22"
        }
    }
}

variable "epg_contracts" {
    description = "epg contracts"
    type        = map
    default     = {
        terraform_one = {
            epg           = "web_epg",
            contract      = "contract_web",
            contract_type = "provider" 
        },
        terraform_two = {
            epg           = "web_epg",
            contract      = "contract_sql",
            contract_type = "consumer" 
        },
        terraform_three = {
            epg           = "db_epg",
            contract      = "contract_sql",
            contract_type = "provider" 
        }
    }
}

variable "vlan_pool" {
    type    = string
    default = "esx-vlan-pool-01"
}

variable "vmm_domain" {
    type    = string
    default = "Psuedoco_ESX"
}