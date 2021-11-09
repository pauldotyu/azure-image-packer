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
    repo    = "pauldotyu/azure-image-packer"
  }

  tenant_id                           = var.tenant_id
  subscription_id                     = var.subscription_id
  client_id                           = var.client_id
  client_secret                       = var.client_secret
  os_type                             = var.os_type
  image_publisher                     = var.image_publisher
  image_offer                         = var.image_offer
  image_sku                           = var.image_sku
  vm_size                             = var.vm_size
  managed_image_resource_group_name   = var.build_resource_group_name
  managed_image_name                  = var.sig_image_name
  build_resource_group_name           = var.build_resource_group_name
  virtual_network_name                = var.virtual_network_name
  virtual_network_subnet_name         = var.virtual_network_subnet_name
  virtual_network_resource_group_name = var.virtual_network_resource_group_name
  user_assigned_managed_identities    = var.user_assigned_managed_identities
  custom_resource_build_prefix        = "pkrwin11" # Windows is a reserved word
  communicator                        = "winrm"
  winrm_insecure                      = "true"
  winrm_timeout                       = "15m"
  winrm_use_ssl                       = "true"
  winrm_username                      = "packer"

  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.sig_resource_group
    gallery_name         = var.sig_name
    image_name           = var.sig_image_name
    image_version        = var.sig_image_version
    replication_regions  = var.sig_image_replication_regions
    storage_account_type = "Standard_LRS"
  }
}

build {
  sources = ["source.azure-arm.cheesehead"]

  provisioner "powershell" {
    scripts = [
      "customizers/say-hello.ps1",
    ]
  }

  # provisioner "powershell" {
  #   script = "customizers/install-from-blob.ps1"
  #   environment_vars = [
  #     "STORAGEACCOUNTNAME=sacheeseheadpacker4",
  #     "CONTAINERNAME=installs",
  #     "BLOBNAME=Git-2.33.1-64-bit.exe",
  #   ]
  # }

  # provisioner "powershell" {
  #   script = "customizers/install-from-blob.ps1"
  #   environment_vars = [
  #     "STORAGEACCOUNTNAME=sacheeseheadpacker4",
  #     "CONTAINERNAME=installs",
  #     "BLOBNAME=VScode.exe",
  #   ]
  # }

  provisioner "powershell" {
    inline = [
      "# NOTE: the following *3* lines are only needed if the you have installed the Guest Agent.",
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "#while ((Get-Service WindowsAzureTelemetryService).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",

      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]

    skip_clean = true
  }
}
