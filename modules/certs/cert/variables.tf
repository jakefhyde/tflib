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
    private_key_pem = string,
    cert_pem        = string,
  })
}

variable "algorithm" {
  type = string
}

variable "rsa_bits" {
  type = number
}

variable "is_ca_certificate" {
  type = bool
}
