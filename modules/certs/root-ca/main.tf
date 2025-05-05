resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "root_ca_key" {
  count    = var.write_files ? 1 : 0
  content  = tls_private_key.ca.private_key_pem
  filename = "${path.cwd}/${var.prefix}-ca.key"
}

resource "tls_self_signed_cert" "root_ca_cert" {
  private_key_pem = tls_private_key.ca.private_key_pem

  is_ca_certificate = true

  subject {
    common_name         = var.subject.common_name
    country             = var.subject.country
    locality            = var.subject.locality
    organization        = var.subject.organization
    organizational_unit = var.subject.organizational_unit
    province            = var.subject.province
    serial_number       = var.subject.serial_number
    street_address      = var.subject.street_address
  }

  validity_period_hours = 168

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "local_sensitive_file" "root_ca_cert" {
  count    = var.write_files ? 1 : 0
  content  = tls_self_signed_cert.root_ca_cert.cert_pem
  filename = "${path.cwd}/${var.prefix}-ca.crt"
}
