locals {
  tags = concat(var.do_tags, [var.prefix])
}

resource "digitalocean_droplet" "droplet" {
  count = var.total

  name     = "${var.prefix}-${count.index}"
  image    = var.do_image
  region   = var.do_region
  size     = var.do_size
  ssh_keys = var.do_ssh_keys

  user_data = var.cloud_init
  tags      = local.tags

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]
  }

  connection {
    type        = "ssh"
    host        = self.ipv4_address
    user        = "root"
    private_key = var.ssh_private_key
  }
}
