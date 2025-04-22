output "cert" {
  value = object({
    private_key_pem = tls_private_key.key.private_key_pem
    cert_pem        = tls_locally_signed_cert.cert.cert_pem
  })
}
