packer {
  required_plugins {
    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

source "azure-arm" "cheesehead" {
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
  communicator                      = "ssh"
  ssh_username                      = var.ssh_user
  ssh_password                      = var.ssh_pass
  ssh_pty                           = true

  #allowed_inbound_ip_addresses = ["x.x.x.x"]

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
    execute_command = "echo '${var.ssh_pass}' | {{ .Vars }} sudo -S -E sh '{{ .Path }}'"
    inline_shebang  = "/bin/sh -x"
    inline = [
      "yum update -y",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    skip_clean = true
  }
}
