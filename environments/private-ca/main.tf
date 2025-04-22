module "ssh" {
  source = "../../modules/ssh"
}

resource random_id "env_name_id" {
  byte_length = 5
}

locals {
  prefix = "${var.prefix}-${random_id.env_name_id.hex}"
}

module "infra" {
  source             = "../../modules/infra/cluster/do"
  prefix             = local.prefix
  public_key_openssh = module.ssh.public_key_openssh
  forwarding_rules = [
    {
      port : 6443
      protocol : "tcp"
      healthcheck : true
    },
    {
      port : 9345
      protocol : "tcp"
    },
    {
      port : 22
      protocol : "tcp"
    },
    {
      port : 80
      protocol : "http"
    },
    {
      port : 443
      protocol : "https"
      tls_passthrough : true
    }
  ]
}

module "rke2_init" {
  source          = "../../modules/k8s/rke2"
  install_version = var.rke2_install_version
  tls_sans = [module.infra.fqdn]
}

module "do_init" {
  source          = "../../modules/infra/machines/do"
  prefix          = local.prefix
  total           = 1
  cloud_init      = module.rke2_init.bootstrap_command
  ssh_private_key = module.ssh.private_key_pem
  do_ssh_keys = [module.infra.ssh_key_fingerprint]
}

resource "ssh_resource" "retrieve_token" {
  host = module.do_init.servers[0].ip
  commands = [
    "sudo cat /var/lib/rancher/rke2/server/node-token"
  ]
  user        = "root"
  private_key = module.ssh.private_key_pem
}

module "rke2_servers" {
  source          = "../../modules/k8s/rke2"
  install_version = var.rke2_install_version
  tls_sans = [module.infra.fqdn] # ip of loadbalancer
  join_input = {
    token    = ssh_resource.retrieve_token.result
    join_url = module.do_init.servers[0].ip
  }
}

module "do_servers" {
  source          = "../../modules/infra/machines/do"
  prefix          = local.prefix
  total           = 2
  cloud_init      = module.rke2_servers.join_command
  ssh_private_key = module.ssh.private_key_pem
  do_ssh_keys = [module.infra.ssh_key_fingerprint]
}

resource "ssh_resource" "retrieve_config" {
  depends_on = [module.do_servers]
  host = module.do_init.servers[0].ip
  commands = [
    "sudo cat /etc/rancher/rke2/rke2.yaml"
  ]
  user        = "root"
  private_key = module.ssh.private_key_pem
}

resource "local_file" "kubeconfig" {
  depends_on = [ssh_resource.retrieve_config]
  filename = "${path.module}/kubeconfig.yaml"
  content = replace(ssh_resource.retrieve_config.result, "127.0.0.1", module.infra.fqdn)
}

resource "time_sleep" "wait_1_minute" {
  depends_on = [module.do_init, local_file.kubeconfig]
  create_duration = "60s"
}

# module "cert_manager" {
#   depends_on = [time_sleep.wait_1_minute]
#   source          = "../../modules/helm/cert_manager"
#   install_version = "v1.17.1"
# }

# Todo: set subjects
# country             = "US"
# locality            = "CA"
# common_name         = "Rancher Root CA"
# organization        = "Rancher Labs"
# organizational_unit = "Rancher Labs Terraform Test Environment"

# I originally signed the ingress cert with tls_private_key.ca.private_key_pem, not sure if that was a mistake

module "root_ca" {
  source    = "../../modules/certs/root-ca"
  prefix    = "${var.prefix}-root-ca"
  algorithm = "RSA"
  rsa_bits  = 2048
  subject = {
    common_name         = "${var.prefix} Root CA"
    organization        = "${var.prefix} Private CA Environment"
    organizational_unit = "${var.prefix} Private CA Environment Terraform Module"
  }
}

module "intermediate_ca" {
  source            = "../../modules/certs/cert"
  prefix            = "${var.prefix}-intermediate-ca"
  algorithm         = "RSA"
  rsa_bits          = 2048
  write_files       = true
  parent_ca         = module.root_ca.cert
  is_ca_certificate = true
  subject = {
    common_name         = "${var.prefix} Intermediate CA"
    organization        = "${var.prefix} Private CA Environment"
    organizational_unit = "${var.prefix} Private CA Environment Terraform Module"
  }
}

module "ingress_cert" {
  source      = "../../modules/certs/cert"
  prefix      = "${var.prefix}-ingress"
  algorithm   = "RSA"
  rsa_bits    = 2048
  write_files = true
  parent_ca   = module.intermediate_ca.cert
  subject = {
    common_name         = "${var.prefix} Rancher Ingress"
    organization        = "${var.prefix} Private CA Environment"
    organizational_unit = "${var.prefix} Private CA Environment Terraform Module"
  }
  dns_names = [module.infra.fqdn]
  set_subject_key_id = true
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "data_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "kubernetes_namespace" "cattle_system" {
  depends_on = [time_sleep.wait_1_minute]
  metadata {
    name = "cattle-system"
  }
}

resource "kubernetes_secret" "ca" {
  depends_on = [kubernetes_namespace.cattle_system]
  metadata {
    name      = "tls-ca"
    namespace = kubernetes_namespace.cattle_system.metadata.name
  }

  data = {
    "cacerts.pem" = module.intermediate_ca.cert.cert_pem
  }
}

resource "kubernetes_secret" "tls" {
  depends_on = [kubernetes_namespace.cattle_system]
  metadata {
    name      = "tls-rancher-ingress"
    namespace = kubernetes_namespace.cattle_system.metadata.name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = module.ingress_cert.cert.cert_pem
    "tls.key" = module.ingress_cert.cert.private_key_pem
  }
}

module "rancher" {
  depends_on = [
    # module.cert_manager,
    kubernetes_secret.ca,
    kubernetes_secret.tls,
  ]
  source               = "../../modules/helm/rancher"
  install_version      = "v2.11-head"
  certificate_strategy = "secret"
  hostname             = module.infra.fqdn
  private_ca           = true
}
