output "servers" {
  value = [for s in digitalocean_droplet.droplet : { ip = s.ipv4_address }]
}
