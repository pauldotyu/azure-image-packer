packer {
  required_plugins {
    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

source "azure-arm" "cheesehead" {
  azure_tags = {
    dept = "Engineering"
    task = "Image deployment"
  }

  tenant_id                         = var.tenant_id
  subscription_id                   = var.subscription_id
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  location                          = var.location
  os_type                           = var.os_type
  image_publisher                   = var.image_publisher
  image_offer                       = var.image_offer
  image_sku                         = var.image_sku
  vm_size                           = var.vm_size
  managed_image_name                = var.sig_image_name
  managed_image_resource_group_name = var.sig_resource_group
  temp_resource_group_name          = var.temp_resource_group_name
  async_resourcegroup_delete        = true

  #allowed_inbound_ip_addresses = ["99.33.64.127"]

  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.sig_resource_group
    gallery_name         = var.sig_name
    image_name           = var.sig_image_name
    image_version        = var.sig_image_version
    replication_regions  = [var.location]
    storage_account_type = "Standard_LRS"
  }
}

build {
  sources = ["source.azure-arm.cheesehead"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline_shebang  = "/bin/sh -x"
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get -y install nginx",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
  }
}
