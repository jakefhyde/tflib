resource "random_password" "bootstrap_password" {
  count  = var.bootstrap_password != "" ? 0 : 1
  length = 48
}

locals {
  bootstrap_password = var.bootstrap_password != "" ? var.bootstrap_password : random_password.bootstrap_password[0].result

  lets_encrypt_settings = var.certificate_strategy == "letsEncrypt" ? {
    "letsEncrypt.email"         = var.lets_encrypt_email
    "letsEncrypt.ingress.class" = "nginx"
  } : {}

  private_ca_settings = var.private_ca ? {
    "privateCA" = true
  } : {}

  cert_settings = merge(local.lets_encrypt_settings, local.private_ca_settings)
}

resource "helm_release" "rancher" {
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  namespace        = "cattle-system"
  create_namespace = true
  wait             = true

  set {
    name  = "hostname"
    value = var.hostname
  }

  set {
    name  = "rancherImagePullPolicy"
    value = "Always"
  }

  set {
    name  = "rancherImageTag"
    value = var.install_version
  }

  set {
    name  = "ingress.tls.source"
    value = var.certificate_strategy
  }

  dynamic "set" {
    for_each = local.cert_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  set {
    name  = "bootstrapPassword"
    value = local.bootstrap_password
  }

  # todo fix
  set {
    name  = "debug"
    value = true
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.rancher]
  create_duration = "30s"
}
