output "bootstrap_command" {
  description = ""
  value = templatefile("${path.module}/user_data/rke2-server-init.sh", {
    TLS_SAN              = var.tls_sans
    INSTALL_RKE2_VERSION = var.install_version
  })
  sensitive = true
}

output "join_command" {
  description = ""
  value       = var.join_input != null ? templatefile("${path.module}/user_data/rke2-server.sh", {
    RKE2_TOKEN           = var.join_input.token
    SERVER               = var.join_input.join_url
    TLS_SAN              = var.tls_sans
    INSTALL_RKE2_VERSION = var.install_version
  }) : null
  sensitive = true
}
