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

# TODO: move to module
resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "ca_key" {
  content  = tls_private_key.ca.private_key_pem
  filename = "${path.cwd}/${var.prefix}-ca.key"
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca.private_key_pem

  is_ca_certificate = true

  subject {
    country             = "US"
    locality            = "CA"
    common_name         = "Rancher Root CA"
    organization        = "Rancher Labs"
    organizational_unit = "Rancher Labs Terraform Test Environment"
  }

  validity_period_hours = 168

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# this is the cacerts
resource "local_sensitive_file" "key" {
  content  = tls_self_signed_cert.ca_cert.cert_pem
  filename = "${path.cwd}/cacerts.pem"
}

resource "tls_private_key" "ca_ingress" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "ca_key_ingress" {
  content  = tls_private_key.ca_ingress.private_key_pem
  filename = "${path.cwd}/tls.key"
}

resource "tls_cert_request" "csr" {
  private_key_pem = tls_private_key.ca_ingress.private_key_pem

  # dns_names = var.dns_names
  dns_names = [module.infra.fqdn]

  subject {
    country             = "US"
    locality            = "CA"
    common_name         = "Rancher Cert Ingress"
    organization        = "Rancher Labs"
    organizational_unit = "Rancher Labs Ingress Terraform Test Environment"
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem   = tls_cert_request.csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 168

  set_subject_key_id = true

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "data_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "local_sensitive_file" "ca_cert_ingress" {
  content  = tls_locally_signed_cert.cert.cert_pem
  filename = "${path.cwd}/tls.crt"
}

# end todo

resource "kubernetes_namespace" "cattle_system_namespace" {
  depends_on = [time_sleep.wait_1_minute]
  metadata {
    name = "cattle-system"
  }
}

resource "kubernetes_secret" "ca" {
  depends_on = [kubernetes_namespace.cattle_system_namespace]
  metadata {
    name      = "tls-ca"
    namespace = "cattle-system"
  }

  data = {
    "cacerts.pem" = local_sensitive_file.key.content
  }
}

resource "kubernetes_secret" "tls" {
  depends_on = [kubernetes_namespace.cattle_system_namespace]
  metadata {
    name      = "tls-rancher-ingress"
    namespace = "cattle-system"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = local_sensitive_file.ca_cert_ingress.content
    "tls.key" = local_sensitive_file.ca_key_ingress.content
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
