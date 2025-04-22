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
    common_name         = string
    country             = string
    locality            = string
    organization        = string
    organizational_unit = string
    province            = string
    serial_number       = string
    street_address      = string
  })
}
