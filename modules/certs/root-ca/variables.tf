variable "write_files" {
  type        = bool
  default     = false
  description = ""
}

variable "prefix" {
  type        = string
  description = ""
}

variable "algorithm" {
  type        = string
  description = ""
}

variable "rsa_bits" {
  type        = number
  description = ""
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
