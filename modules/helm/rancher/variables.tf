variable "bootstrap_password" {
  type        = string
  description = "Password to use for bootstrapping Rancher"
  default     = ""
}

variable "hostname" {
  description = ""
  type        = string
}

variable "debug" {
  type        = bool
  description = ""
  default     = true
}

variable "install_version" {
  type        = string
  description = ""
  default     = "v2.11-head"
}

variable "certificate_strategy" {
  type = string

  validation {
    condition = contains(["rancher", "letsEncrypt", "secret"], var.certificate_strategy)
    error_message = "Allows values for certificate_strategy are \"rancher\", \"letsEncrypt\", or \"secret\"."
  }
}

variable "private_ca" {
  type        = bool
  description = ""
  default     = false
}

variable "lets_encrypt_email" {
  type        = string
  description = "Lets encrypt email"
  default     = ""
}
