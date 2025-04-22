resource "tls_private_key" "intermediate_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "intermediate_ca_key" {
  count    = var.write_files ? 1 : 0
  content  = tls_private_key.intermediate_ca.private_key_pem
  filename = "${path.cwd}/${var.prefix}-intermediate-ca.key"
}

module "cert" {
  source = "../cert"
  parent_ca = {
    
  }
  prefix = ""
}

resource "tls_cert_request" "intermediate_ca" {
  key_algorithm   = tls_private_key.intermediate_ca.algorithm
  private_key_pem = tls_private_key.intermediate_ca.private_key_pem

  subject {

  }
}

resource "tls_locally_signed_cert" "intermediate_ca" {
  cert_request_pem = tls_cert_request.intermediate_ca.cert_request_pem

  ca_private_key_pem = var.parent_ca.private_key_pem
  ca_cert_pem        = var.parent_ca.root_ca.cert_pem

  is_ca_certificate     = true
  validity_period_hours = 168

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "local_sensitive_file" "intermediate_ca_cert" {
  count    = var.write_files ? 1 : 0
  content  = tls_locally_signed_cert.intermediate_ca.cert_pem
  filename = "${path.cwd}/${var.prefix}-intermediate-ca.crt"
}
