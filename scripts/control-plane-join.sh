#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Configure Additional Kubernetes Control-Plane Node                              ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Installing kubeadm and kubectl..."
dnf install -y kubeadm kubectl --disableexcludes=kubernetes

if [ ! -f /etc/kubernetes/admin.conf ]
then
    echo "Installing and configuring bash-completion..."
    dnf install -y bash-completion
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
fi

if [ ! -f /usr/local/bin/helm ]
then
    echo "Downloading and installing Helm v${HELM_VERSION}..."
    HELM_ARCH=amd64
    cd /tmp
    curl -L --fail --remote-name-all https://get.helm.sh/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz.sha256sum
    mkdir -p /usr/local/share/helm
    tar xzvfC helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz /usr/local/share/helm
    ln -s /usr/local/share/helm/linux-${HELM_ARCH}/helm /usr/local/bin/helm
    rm helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz{,.sha256sum}
    cd ~
fi

JOIN_CONFIG_PATH=/tmp/join-config.yml
if [ ! -f "${JOIN_CONFIG_PATH}" ]
then
    echo "Joining the cluster as a control-plane..."
    cp /vagrant_work/join-config.yml.part "${JOIN_CONFIG_PATH}"
    cat <<EOF >> "${JOIN_CONFIG_PATH}"
controlPlane:
  localAPIEndpoint:
    advertiseAddress: '${KUBE_API_ENDPOINT}'
    bindPort: 6443
  certificateKey: ${KUBE_CERTIFICATE_KEY}
nodeRegistration:
  criSocket: 'unix:///var/run/crio/crio.sock'
  name: ${HOSTNAME}
EOF
    kubeadm config images pull
    kubeadm join --config="${JOIN_CONFIG_PATH}"
fi

if [ ! -f "${HOME}/.kube/config" ]
then
    echo "Enabling kubectl access for root..."
    mkdir -p "${HOME}/.kube"
    cp -i /etc/kubernetes/admin.conf "${HOME}/.kube/config"
fi

if [ ! -f /usr/local/bin/cilium ]
then
    echo "Downloading and installing the latest Cilium client..."
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    CILIUM_CLI_ARCH=amd64
    cd /tmp
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CILIUM_CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CILIUM_CLI_ARCH}.tar.gz.sha256sum
    tar xzvfC cilium-linux-${CILIUM_CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${CILIUM_CLI_ARCH}.tar.gz{,.sha256sum}
    cd ~
fi
