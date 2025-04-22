output "cert" {
  value = object({
    private_key_pem = tls_private_key.ca.private_key_pem
    cert_pem        = tls_self_signed_cert.root_ca_cert.cert_pem
  })
}
