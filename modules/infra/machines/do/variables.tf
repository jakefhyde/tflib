# Infra module contract variables

variable "prefix" {
  description = "prefix for all DO created resources."
  type        = string
}

variable "total" {
  description = ""
  type        = number
}

variable "cloud_init" {
  description = ""
  type        = string
}

variable "ssh_private_key" {
  description = ""
  type        = string
}

variable "ssh_user" {
  description = ""
  type        = string
  default     = "root"
}

# Digital Ocean specific variables

variable "do_region" {
  description = ""
  type        = string
  default     = "nyc3"
}

variable "do_image" {
  description = ""
  type        = string
  default     = "ubuntu-20-04-x64"
}

variable "do_size" {
  description = ""
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "do_ssh_keys" {
  description = ""
  type = list(string)
}

variable "do_tags" {
  description = "User defined tags to add to droplet"
  type = list(string)
  default = []
}
