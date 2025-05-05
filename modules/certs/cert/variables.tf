variable "prefix" {
  type        = string
  description = ""
}

variable "algorithm" {
  type = string
}

variable "rsa_bits" {
  type = number
}

variable "write_files" {
  type        = bool
  default     = false
  description = ""
}

variable "parent_ca" {
  description = ""
  type = object({
    private_key_pem = string,
    cert_pem        = string,
  })
}

variable "is_ca_certificate" {
  type        = bool
  default     = false
  description = ""
}

variable "dns_names" {
  type = list(string)
  description = ""
  default     = null
}

variable "set_subject_key_id" {
  type    = bool
  default = false
}

variable "allowed_uses" {
  type = list(string)
  default = [
    "digital_signature",
    "key_encipherment",
    "cert_signing",
  ]
}

variable "subject" {
  type = object({
    common_name = optional(string)
    country = optional(string)
    locality = optional(string)
    organization = optional(string)
    organizational_unit = optional(string)
    province = optional(string)
    serial_number = optional(string)
    street_address = optional(list(string))
  })
}
