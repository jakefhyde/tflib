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
  key_algorithm   = tls_private_key.key.algorithm
  private_key_pem = tls_private_key.key.private_key_pem

  subject {

  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.csr.cert_request_pem

  ca_private_key_pem = var.parent_ca.private_key_pem
  ca_cert_pem        = var.parent_ca.root_ca.cert_pem

  is_ca_certificate     = var.is_ca_certificate
  validity_period_hours = 168

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "local_sensitive_file" "cert" {
  count    = var.write_files ? 1 : 0
  content  = tls_locally_signed_cert.cert.cert_pem
  filename = "${path.cwd}/${var.prefix}.crt"
}
