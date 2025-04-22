variable "install_version" {
  description = ""
  type        = string
}

variable "join_input" {
  description = ""
  type = object({
    token    = string
    join_url = string
  })
  default = null
}

variable "tls_sans" {
  description = ""
  type = list(string)
  default = []
}
