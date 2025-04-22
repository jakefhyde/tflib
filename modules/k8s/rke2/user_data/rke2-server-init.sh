#!/bin/bash

mkdir -p /etc/rancher/rke2
cat > /etc/rancher/rke2/config.yaml <<- EOF
write-kubeconfig-mode: 644
cni: calico
tls-san:
${yamlencode(TLS_SAN)}
EOF

curl https://get.rke2.io | INSTALL_RKE2_VERSION="${INSTALL_RKE2_VERSION}" sh -s -

systemctl enable rke2-server
systemctl start rke2-server
