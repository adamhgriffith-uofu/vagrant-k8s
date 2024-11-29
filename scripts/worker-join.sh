#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Configure Kubernetes Worker Node                                                ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Installing kubeadm..."
dnf install -y kubeadm --disableexcludes=kubernetes

JOIN_CONFIG_PATH=/tmp/join-config.yml
if [ ! -f "${JOIN_CONFIG_PATH}" ]
then
    echo "Joining the cluster as a worker..."
    cp /vagrant_work/join-config.yml.part "${JOIN_CONFIG_PATH}"
    cat <<EOF >> "${JOIN_CONFIG_PATH}"
nodeRegistration:
  criSocket: 'unix:///var/run/crio/crio.sock'
  name: ${HOSTNAME}
EOF
    kubeadm config images pull
    kubeadm join --config="${JOIN_CONFIG_PATH}"
fi
