#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Apply Node Requirements                                                         ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Setting SELinux to disabled mode..."
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

echo "Disabling swap..."
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab

echo "Loading kernel module dependencies..."
cat <<EOF > /etc/modules-load.d/cri-o.conf
br_netfilter
EOF
modprobe br_netfilter

echo "Disabling firewalld..."
systemctl disable --now firewalld

echo "Enabling IP forwarding..."
cat <<EOF > /etc/sysctl.d/02-fwd.conf
net.ipv4.conf.all.forwarding=1
EOF

echo "Applying changes..."
sysctl --system
systemctl restart NetworkManager

echo "Ensuring ipvsadm is installed..."
dnf install -y ipvsadm

echo "Ensuring container-selinux is installed..."
dnf install -y container-selinux

echo "Adding the kubernetes.repo file for v${KUBE_VERSION}..."
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo "Adding the cri-o.repo file for v${CRIO_VERSION}..."
cat <<EOF > /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/stable:/v${CRIO_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/stable:/v${CRIO_VERSION}/rpm/repodata/repomd.xml.key
EOF

echo "Installing cri-o..."
dnf install -y cri-o

echo "Installing kubelet..."
dnf install -y kubelet --disableexcludes=kubernetes

echo "Enabling and starting crio service..."
systemctl enable --now crio.service

echo "Enabling Kublet through systemctl..."
systemctl enable --now kubelet