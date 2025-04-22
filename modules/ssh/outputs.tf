output "public_key_openssh" {
  value = tls_private_key.global_key.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.global_key.private_key_pem
  sensitive = true
}
