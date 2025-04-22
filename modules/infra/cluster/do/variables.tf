# Cluster infrastructure module contract variables

variable "prefix" {
  description = "prefix for all DO created resources."
  type        = string
}

variable "public_key_openssh" {
  description = ""
  type        = string
}

# Digital Ocean specific variables

variable "do_domain" {
  type    = string
  default = "cp-dev.rancher.space"
}

variable "do_region" {
  description = ""
  type        = string
  default     = "nyc3"
}

variable "forwarding_rules" {
  description = ""
  type = list(object({
    tls_passthrough = optional(bool)
    protocol = string,
    port     = number,
    healthcheck = optional(bool)
  }))
}
