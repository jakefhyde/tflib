output "fqdn" {
  value = digitalocean_record.dns.fqdn
}

output "ssh_key_fingerprint" {
  value     = digitalocean_ssh_key.ssh_key.fingerprint
  sensitive = true
}
