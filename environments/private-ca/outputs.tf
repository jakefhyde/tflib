output "rancher_server_url" {
  value = "https://${module.infra.fqdn}"
}

output "rancher_server_password" {
  value     = module.rancher.password
  sensitive = true
}
