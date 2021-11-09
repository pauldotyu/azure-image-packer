variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "os_type" {
  type = string
}

variable "image_publisher" {
  type = string
}

variable "image_offer" {
  type = string
}

variable "image_sku" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "sig_resource_group" {
  type = string
}

variable "sig_name" {
  type = string
}

variable "sig_image_name" {
  type = string
}

variable "sig_image_version" {
  type = string
}

variable "sig_image_replication_regions" {
  type = list(string)
}

variable "user_assigned_managed_identities" {
  type = list(string)
}

variable "build_resource_group_name" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "virtual_network_subnet_name" {
  type = string
}

variable "virtual_network_resource_group_name" {
  type = string
}
