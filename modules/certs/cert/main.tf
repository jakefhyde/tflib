resource "tls_private_key" "key" {
  algorithm = var.algorithm
  rsa_bits  = var.rsa_bits
}

resource "local_sensitive_file" "key" {
  count    = var.write_files ? 1 : 0
  content  = tls_private_key.key.private_key_pem
  filename = "${path.cwd}/${var.prefix}.key"
}

resource "tls_cert_request" "csr" {
  private_key_pem = tls_private_key.key.private_key_pem

  dns_names = var.dns_names

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
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.csr.cert_request_pem

  ca_private_key_pem = var.parent_ca.private_key_pem
  ca_cert_pem        = var.parent_ca.cert_pem

  is_ca_certificate     = var.is_ca_certificate
  validity_period_hours = 168

  set_subject_key_id = var.set_subject_key_id

  allowed_uses = var.allowed_uses
}

resource "local_sensitive_file" "cert" {
  count    = var.write_files ? 1 : 0
  content  = tls_locally_signed_cert.cert.cert_pem
  filename = "${path.cwd}/${var.prefix}.crt"
}
