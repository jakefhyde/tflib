# Temporary key pair used for SSH access
resource "digitalocean_ssh_key" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = var.public_key_openssh
}

resource "digitalocean_loadbalancer" "loadbalancer" {
  name        = "${var.prefix}-lb"
  region      = var.do_region
  droplet_tag = var.prefix

  dynamic "forwarding_rule" {
    for_each = var.forwarding_rules
    content {
      tls_passthrough = forwarding_rule.value.tls_passthrough
      entry_port      = forwarding_rule.value.port
      entry_protocol  = forwarding_rule.value.protocol
      target_port     = forwarding_rule.value.port
      target_protocol = forwarding_rule.value.protocol
    }
  }

  dynamic "healthcheck" {
    for_each = [for a in var.forwarding_rules : a if a.healthcheck == true]
    content {
      port                     = healthcheck.value.port
      protocol                 = healthcheck.value.protocol
      check_interval_seconds   = 10
      response_timeout_seconds = 10
      healthy_threshold        = 5
      unhealthy_threshold      = 3
    }
  }
}

resource "digitalocean_record" "dns" {
  domain = var.do_domain
  type   = "A"
  name   = var.prefix
  value  = digitalocean_loadbalancer.loadbalancer.ip
  ttl    = 1800
}
