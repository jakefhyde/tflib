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
