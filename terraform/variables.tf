variable "location" {
  type = string
}

variable "vnet_address_prefixes" {
  type = list(string)
}

variable "snet_aci_address_prefixes" {
  type = list(string)
}

variable "snet_pkr_address_prefixes" {
  type = list(string)
}

variable "images" {
  type = list(object({
    name               = string
    os_type            = string
    hyper_v_generation = string
    publisher          = string
    offer              = string
    sku                = string
  }))
  default = [
    {
      name               = "windows11-m365"
      os_type            = "Windows"
      hyper_v_generation = "V2"
      publisher          = "Contoso"
      offer              = "AVD"
      sku                = "Windows11-M365"
    },
    {
      name               = "ubuntu1804-hpc"
      os_type            = "Linux"
      hyper_v_generation = "V1"
      publisher          = "Contoso"
      offer              = "HPC"
      sku                = "Ubuntu1804-HPC"
    },
    {
      name               = "centos79-hpc"
      os_type            = "Linux"
      hyper_v_generation = "V1"
      publisher          = "Contoso"
      offer              = "HPC"
      sku                = "Centos79-HPC"
    }
  ]
}

variable "azdo_url" {
  type = string
}

variable "azdo_agent_name" {
  type = string
}

variable "azdo_agent_pool" {
  type = string
}

variable "azdo_token" {
  type = string
}

variable "acr_build_no_wait" {
  type        = string
  description = "If you do not want to wait for the ACR build task to complete, pass in this value: --no-wait"
  default     = ""
}