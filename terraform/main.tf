provider "azurerm" {
  features {}
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "http" "ifconfig" {
  url = "http://ifconfig.me"
}

resource "random_pet" "packer" {
  length    = 2
  separator = ""
}

resource "azurerm_resource_group" "packer" {
  name     = "rg-${random_pet.packer.id}"
  location = "westus2"
}

resource "azurerm_shared_image_gallery" "packer" {
  name                = "sig${random_pet.packer.id}"
  resource_group_name = azurerm_resource_group.packer.name
  location            = azurerm_resource_group.packer.location
  description         = "Shared images and things."
}

resource "azurerm_shared_image" "packer" {
  for_each            = { for img in var.images : img.name => img }
  name                = each.value["name"]
  gallery_name        = azurerm_shared_image_gallery.packer.name
  resource_group_name = azurerm_resource_group.packer.name
  location            = azurerm_resource_group.packer.location
  os_type             = each.value["os_type"]
  hyper_v_generation  = each.value["hyper_v_generation"]

  identifier {
    publisher = each.value["publisher"]
    offer     = each.value["offer"]
    sku       = each.value["sku"]
  }
}

resource "azurerm_virtual_network" "packer" {
  name                = "vn-${random_pet.packer.id}"
  address_space       = var.vnet_address_prefixes
  location            = azurerm_resource_group.packer.location
  resource_group_name = azurerm_resource_group.packer.name
}

resource "azurerm_subnet" "aci" {
  name                 = "sn-aci-${random_pet.packer.id}"
  resource_group_name  = azurerm_resource_group.packer.name
  virtual_network_name = azurerm_virtual_network.packer.name

  address_prefixes = var.snet_address_prefixes

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
  ]

  delegation {
    name = "Microsoft.ContainerInstance.containerGroups"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_profile" "aci" {
  name                = "np-aci-${random_pet.packer.id}"
  resource_group_name = azurerm_resource_group.packer.name
  location            = azurerm_resource_group.packer.location

  container_network_interface {
    name = "nic-aci-${random_pet.packer.id}"

    ip_configuration {
      name      = "ipconfig1"
      subnet_id = azurerm_subnet.aci.id
    }
  }
}

resource "azurerm_network_security_group" "aci" {
  name                = "nsg-aci-${random_pet.packer.id}"
  resource_group_name = azurerm_resource_group.packer.name
  location            = azurerm_resource_group.packer.location
}

resource "azurerm_subnet_network_security_group_association" "aci" {
  subnet_id                 = azurerm_subnet.aci.id
  network_security_group_id = azurerm_network_security_group.aci.id
}

resource "azurerm_container_registry" "packer" {
  name                = "acr${random_pet.packer.id}"
  resource_group_name = azurerm_resource_group.packer.name
  location            = azurerm_resource_group.packer.location
  sku                 = "Premium"
  admin_enabled       = true
}

resource "null_resource" "acr_build" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "az acr build -t azpagent/packer:latest -r ${azurerm_container_registry.packer.login_server} ${var.acr_build_no_wait} ../azpagent"
  }

  depends_on = [
    azurerm_container_registry.packer
  ]
}

resource "azuread_application" "packer" {
  display_name = "spn-${random_pet.packer.id}"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "packer" {
  application_id               = azuread_application.packer.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "time_rotating" "packer" {
  rotation_days = 365
}

resource "azuread_service_principal_password" "packer" {
  service_principal_id = azuread_service_principal.packer.object_id
  rotate_when_changed = {
    rotation = time_rotating.packer.id
  }
}

resource "azurerm_role_assignment" "packer" {
  scope                = azurerm_container_registry.packer.id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.packer.object_id
}

resource "azurerm_container_group" "packer" {
  name                = "aci-${random_pet.packer.id}"
  resource_group_name = azurerm_resource_group.packer.name
  location            = azurerm_resource_group.packer.location
  os_type             = "Linux"
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.aci.id

  # identity {
  #   type = "SystemAssigned"
  # }

  image_registry_credential {
    username = azuread_application.packer.application_id
    password = azuread_service_principal_password.packer.value
    server   = azurerm_container_registry.packer.login_server
  }

  container {
    name   = "aci-${random_pet.packer.id}"
    image  = "${azurerm_container_registry.packer.login_server}/azpagent/packer:latest"
    cpu    = 1
    memory = 1

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      AZP_URL        = var.azdo_url
      AZP_AGENT_NAME = var.azdo_agent_name
      AZP_POOL       = var.azdo_agent_pool
    }

    secure_environment_variables = {
      AZP_TOKEN = var.azdo_token
    }
  }

  depends_on = [
    null_resource.acr_build
  ]
}
