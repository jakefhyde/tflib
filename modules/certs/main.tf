terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "ca_key" {
  content  = tls_private_key.ca.private_key_pem
  filename = "${path.cwd}/${prefix}-ca.key"
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca.private_key_pem

  is_ca_certificate = true

  subject {
    country             = "US"
    locality            = "CA"
    common_name         = "Rancher Root CA"
    organization        = "Rancher Labs"
    organizational_unit = "Rancher Labs Terraform Test Environment"
  }

  validity_period_hours = 168

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# this is the cacerts
resource "local_sensitive_file" "key" {
  # count    = var.write_files ? 1 : 0
  content  = tls_self_signed_cert.ca_cert.cert_pem
  filename = "${path.cwd}/${prefix}-ca.pem"
}

resource "tls_private_key" "ca_ingress" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "ca_key_ingress" {
  content  = tls_private_key.ca_ingress.private_key_pem
  filename = "${path.cwd}/${prefix}-ca-ingress.key"
}

resource "tls_cert_request" "csr" {
  private_key_pem = tls_private_key.ca_ingress.private_key_pem

  dns_names = var.dns_names

  subject {
    country             = "US"
    locality            = "CA"
    common_name         = "Rancher Cert Ingress"
    organization        = "Rancher Labs"
    organizational_unit = "Rancher Labs Ingress Terraform Test Environment"
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem   = tls_cert_request.csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 168

  set_subject_key_id = true

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "data_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "local_sensitive_file" "ca_key_ingress" {
  content  = tls_locally_signed_cert.cert.cert_pem
  filename = "${path.cwd}/${prefix}-ca-ingress.crt"
}

# resource "local_sensitive_file" "cert" {
#   # count    = var.write_files ? 1 : 0
#   content  = tls_locally_signed_cert.cert.cert_pem
#   filename = "${path.cwd}/${prefix}.cert"
# }

# resource "tls_cert_request" "csr" {
#   private_key_pem = tls_private_key.ca.private_key_pem
#
#   dns_names = var.dns_names
#
#   subject {
#     country             = "US"
#     locality            = "CA"
#     common_name         = "Rancher Cert"
#     organization        = "Rancher Labs"
#     organizational_unit = "Rancher Labs Terraform Test Environment"
#   }
# }
#
# resource "tls_locally_signed_cert" "cert" {
#   cert_request_pem   = tls_cert_request.csr.cert_request_pem
#   ca_private_key_pem = tls_private_key.ca.private_key_pem
#   ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem
#
#   validity_period_hours = 168
#
#   allowed_uses = [
#     "digital_signature",
#     "key_encipherment",
#     "server_auth",
#     "client_auth",
#   ]
# }
#
# resource "local_sensitive_file" "cert" {
#   # count    = var.write_files ? 1 : 0
#   content  = tls_locally_signed_cert.cert.cert_pem
#   filename = "${path.cwd}/${prefix}.cert"
# }
