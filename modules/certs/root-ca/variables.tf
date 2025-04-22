variable "write_files" {
  type        = bool
  default     = false
  description = ""
}

variable "prefix" {
  type        = string
  description = ""
}

variable "parent_ca" {
  type = object({
    ca_key_algorithm   = string,
    ca_private_key_pem = string,
    ca_cert_pem        = string,
  })
}
