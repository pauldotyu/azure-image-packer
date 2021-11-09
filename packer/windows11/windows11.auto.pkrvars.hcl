os_type                       = "Windows"
image_publisher               = "microsoftwindowsdesktop"
image_offer                   = "office-365"
image_sku                     = "win11-21h2-avd-m365"
vm_size                       = "Standard_D4s_v4"
sig_resource_group            = "rg-cheesehead"
sig_name                      = "sigcheesehead"
sig_image_name                = "windows11-m365"
sig_image_replication_regions = ["westus2"]

user_assigned_managed_identities = [
  "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/rg-cheesehead/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-packer"
]

build_resource_group_name           = "rg-cheesehead"
virtual_network_resource_group_name = "rg-cheesehead"
virtual_network_name                = "vn-cheesehead"
virtual_network_subnet_name         = "sn-packer"