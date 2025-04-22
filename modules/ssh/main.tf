resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "ssh_private_key_pem" {
  count           = var.create_ssh_key_files == true ? 1 : 0
  filename        = "${path.cwd}/id_rsa"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  count    = var.create_ssh_key_files == true ? 1 : 0
  filename = "${path.cwd}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}
